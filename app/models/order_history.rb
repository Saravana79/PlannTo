class OrderHistory < ActiveRecord::Base
  validates :order_date, :total_revenue, :vendor_ids, presence: true

  belongs_to :add_impression, :foreign_key => :impression_id
  belongs_to :vendor, :foreign_key => :vendor_ids
  belongs_to :payment_report
  belongs_to :advertisement
  after_save :create_record_in_m_order_history
  after_create :update_orders_in_aggregated_impression

  def self.update_order_histories_from_reports
    [Date.today - 1.day, Date.today].each do |date|
      begin
        OrderHistory.update_orders_from_amazon(date)
      rescue Exception => e
        p e.backtrace
      end
    end
  end

  def self.update_orders_from_amazon(date)
    users = [["pla04", "cyn04"], ["interactive", "vagrenpgvir", "interactiv0e4"]]
    users.each do |user|
      begin
        filename = OrderHistory.generate_filename(user, date)
        url = "https://assoc-datafeeds-eu.amazon.com/datafeed/getReport?filename=#{filename}"
        xml_response = OrderHistory.get_order_details_from_amazon(url, user[0], user[1])

        doc = Nokogiri::XML.parse(xml_response)
        node = doc.elements.first
        items_node = node.at_xpath("//Items")
        items_node.xpath("Item").each do |item|
          # order_history = OrderHistory.new(:order_date => date, :no_of_orders => 1, :vendor_ids => 9882, :order_status => "Validated", :payment_status => "Validated")
          impression_id = item.attributes["SubTag"].content
          revenue = item.attributes["Earnings"].content rescue 0
          price = item.attributes["Price"].content rescue 0
          impression = AddImpression.where(:id => impression_id).first
          time = impression.blank? ? date.to_time: impression.impression_time.to_time rescue Time.now

          order_history = OrderHistory.find_or_initialize_by_order_date_and_impression_id_and_total_revenue(time, impression_id, revenue)
          order_history.vendor_ids = 9882
          order_history.product_price = price
          order_history.no_of_orders = 1
          order_history.order_status = "Validated"
          order_history.payment_status = "Validated"

          unless impression.blank?
            PlanntoUserDetail.update_plannto_user_detail(impression)

            order_history.item_id = impression.item_id
            product = impression.item
            order_history.item_name = product.name unless product.blank?
            order_history.sid = impression.sid
            order_history.advertisement_id = impression.advertisement_id
            order_history.publisher_id = impression.publisher_id
          end
          order_history.save!
        end
      rescue Exception => e
        p "Error in order update"
      end
    end
  end

  def self.generate_filename(user, date)
    date_int = date.strftime("%Y%m%d")
    prefix_val = user[0]
    prefix_val = user[2].to_s if !user[2].to_s.blank?
    filename = "#{prefix_val}-21-earnings-report-#{date_int}.xml.gz"
  end

  #url => "https://assoc-datafeeds-eu.amazon.com/datafeed/listReports"
  #username => "pla04"
  #password => "cyn04"
  def self.get_order_details_from_amazon(url, username, password )
    # require 'uri'
    # require 'net/http'
    # require 'net/http/digest_auth'

    digest_auth = Net::HTTP::DigestAuth.new

    uri = URI.parse(url)
    uri.user = username
    uri.password = password

    h = Net::HTTP.new uri.host, uri.port
    h.use_ssl = true
    h.ssl_version = :TLSv1

    req = Net::HTTP::Get.new uri.request_uri

    res = h.request req
    # res is a 401 response with a WWW-Authenticate header

    auth = digest_auth.auth_header uri, res['www-authenticate'], 'GET'

    # create a new request with the Authorization header
    req = Net::HTTP::Get.new uri.request_uri
    req.add_field 'Authorization', auth

    # re-issue request with Authorization
    res = h.request req

    if res.kind_of?(Net::HTTPFound)
      location = res["location"]
      response = RestClient.get(location)
      #extract gz file
      xml_response = ActiveSupport::Gzip.decompress(response)
      xml_response
    else
      res.body
    end
  end

  def self.update_orders_from_flipkart(url)
    csv_details = CSV.read(url)

    headers = []
    csv_details.each_with_index do |csv_detail, index|
      if index == 0
        headers = csv_detail
        next
      end

      order_history = OrderHistory.find_or_initialize_by_order_item_id(csv_detail[headers.index("AffiliateOrderItemId")])
      time = csv_detail[headers.index("OrderDate")].to_time
      time = time + 5.30.hours if time.is_a?(Time)
      order_history.order_date = time
      order_history.impression_id = csv_detail[headers.index("AffExtParam2")]
      order_history.total_revenue = csv_detail[headers.index("TentativeCommission")]
      order_history.vendor_ids = 9861
      order_history.product_price = csv_detail[headers.index("Price")]
      order_history.no_of_orders = 1
      order_history.order_status = "Validated"
      order_history.payment_status = "Validated"
      order_history.item_name = csv_detail[headers.index("Title")]

      impression = csv_detail[headers.index("AffExtParam2")].blank? ? nil : AddImpression.where(:id => csv_detail[headers.index("AffExtParam2")]).first

      unless impression.blank?
        PlanntoUserDetail.update_plannto_user_detail(impression)

        order_history.item_id = impression.item_id
        order_history.sid = impression.sid
        order_history.advertisement_id = impression.advertisement_id
        order_history.publisher_id = impression.publisher_id
      end
      order_history.save!
    end
  end

  private

  def create_record_in_m_order_history
    imp_id = self.impression_id
    imp = AdImpression.where(:_id => imp_id).first
    unless imp.blank?
      m_order_history = imp.m_order_histories.where(:order_history_id => self.id).first
      unless m_order_history.blank?
        m_order_history.total_revenue = self.total_revenue
        m_order_history.save
      else
        imp.m_order_histories << MOrderHistory.new(:order_history_id => self.id, :total_revenue => self.total_revenue)
      end
    end
  end

  def update_orders_in_aggregated_impression
    # Update AggregatedImpression
    impression = AddImpression.where(:id => self.impression_id).last

    if !impression.blank?
      time = impression.impression_time.to_time.utc rescue Time.now
      date = time.to_date rescue ""
      hour = time.hour rescue ""
      if !impression.advertisement_id.blank?
        is_rii = self.advertisement.having_related_items rescue false
        url_params = Advertisement.reverse_make_url_params(impression.params)
        url_params.symbolize_keys!
        device_name = url_params[:device].to_s
        ret_val = url_params[:r].to_i == 1

        agg_imp = AggregatedImpression.where(:agg_date => date, :ad_id => self.advertisement_id).last
        if agg_imp.blank?
          agg_imp = AggregatedImpression.new(:agg_date => date, :ad_id => self.advertisement_id, :total_orders => 1)
          agg_imp.save!
        else
          agg_imp.total_orders = agg_imp.total_orders.to_i + 1
          agg_imp.save!
        end

        hours = agg_imp.hours.blank? ? {} : agg_imp.hours
        if hours["#{hour}"].blank?
          hours.merge!({"#{hour}" => {"orders" => 1}})
        else
          hours["#{hour}"].merge!({"orders" => hours["#{hour}"]["orders"].to_i + 1})
        end

        device = agg_imp.device.blank? ? {} : agg_imp.device
        if device["#{device_name}"].blank?
          device.merge!({"#{device_name}" => {"orders" => 1}})
        else
          device["#{device_name}"].merge!({"orders" => device["#{device_name}"]["orders"].to_i + 1})
        end

        rii = agg_imp.rii.blank? ? {} : agg_imp.rii
        if rii["#{is_rii}"].blank?
          rii.merge!({"#{is_rii}" => {"orders" => 1}})
        else
          rii["#{is_rii}"].merge!({"orders" => rii["#{is_rii}"]["orders"].to_i + 1})
        end

        ret = agg_imp.ret.blank? ? {} : agg_imp.ret
        if ret["#{ret_val}"].blank?
          ret.merge!({"#{ret_val}" => {"orders" => 1}})
        else
          ret["#{ret_val}"].merge!({"orders" => ret["#{ret_val}"]["orders"].to_i + 1})
        end

        # agg_imp.hours = Advertisement.combine_hash(agg_imp.hours, hours)
        # agg_imp.device = Advertisement.combine_hash(agg_imp.device, device)
        # agg_imp.ret = Advertisement.combine_hash(agg_imp.ret, ret)
        # agg_imp.rii = Advertisement.combine_hash(agg_imp.rii, rii)
        agg_imp.hours = hours
        agg_imp.device = device
        agg_imp.ret = ret
        agg_imp.rii = rii
        agg_imp.save!

        #AggregatedImpression By Item
        agg_imp_by_item = AggregatedImpressionByType.where(:agg_date => date, :ad_id => self.advertisement_id, :agg_type => "Item").last
        if agg_imp_by_item.blank?
          agg_imp_by_item = AggregatedImpressionByType.new(:agg_date => date, :ad_id => self.advertisement_id, :total_orders => 1, :agg_type => "Item")
          agg_imp_by_item.save!
        end

        item_agg_coll = agg_imp_by_item.agg_coll.blank? ? {} : agg_imp_by_item.agg_coll
        if item_agg_coll["#{self.item_id}"].blank?
          item_agg_coll.merge!({"#{self.item_id}" => {"orders" => 1}})
        else
          item_agg_coll["#{self.item_id}"].merge!({"orders" => item_agg_coll["#{self.item_id}"]["orders"].to_i + 1})
        end
        agg_imp_by_item.agg_coll = item_agg_coll
        agg_imp_by_item.save!

        #AggregatedImpression By Domain
        domain = Item.get_host_without_www(impression.hosted_site_url)
        agg_imp_by_domain = AggregatedImpressionByType.where(:agg_date => date, :ad_id => self.advertisement_id, :agg_type => "Domain").last
        if agg_imp_by_domain.blank?
          agg_imp_by_domain = AggregatedImpressionByType.new(:agg_date => date, :ad_id => self.advertisement_id, :total_orders => 1, :agg_type => "Domain")
          agg_imp_by_domain.save!
        end

        domain = domain.to_s.gsub(".", "^")

        domain_agg_coll = agg_imp_by_domain.agg_coll.blank? ? {} : agg_imp_by_domain.agg_coll
        domain_agg_coll = Hash[domain_agg_coll.map {|k, v| [k.gsub(".", "^"), v] }]
        if domain_agg_coll["#{domain}"].blank?
          domain_agg_coll.merge!({"#{domain}" => {"orders" => 1}})
        else
          domain_agg_coll["#{domain}"].merge!({"orders" => domain_agg_coll["#{domain}"]["orders"].to_i + 1})
        end
        agg_imp_by_domain.agg_coll = domain_agg_coll
        agg_imp_by_domain.save!

      else
        agg_imp = AggregatedImpression.where(:agg_date => date, :ad_id => nil, :for_pub => true).last
        if agg_imp.blank?
          agg_imp = AggregatedImpression.new(:agg_date => date, :ad_id => nil, :for_pub => true, :total_orders => 1)
          agg_imp.save!
        else
          agg_imp.total_orders = agg_imp.total_orders.to_i + 1
          agg_imp.save!
        end
      end
    elsif !self.advertisement_id.blank?
      time = self.order_date.to_time.utc rescue Time.now
      date = time.to_date rescue ""

      agg_imp = AggregatedImpression.where(:agg_date => date, :ad_id => self.advertisement_id).last
      if agg_imp.blank?
        agg_imp = AggregatedImpression.new(:agg_date => date, :ad_id => self.advertisement_id, :total_orders => 1)
        agg_imp.save!
      else
        agg_imp.total_orders = agg_imp.total_orders.to_i + 1
        agg_imp.save!
      end

      #AggregatedImpression By Item
      agg_imp_by_item = AggregatedImpressionByType.where(:agg_date => date, :ad_id => self.advertisement_id, :agg_type => "Item").last
      if agg_imp_by_item.blank?
        agg_imp_by_item = AggregatedImpressionByType.new(:agg_date => date, :ad_id => self.advertisement_id, :total_orders => 1, :agg_type => "Item")
        agg_imp_by_item.save!
      end

      item_agg_coll = agg_imp_by_item.agg_coll.blank? ? {} : agg_imp_by_item.agg_coll
      if item_agg_coll["#{self.item_id}"].blank?
        item_agg_coll.merge!({"#{self.item_id}" => {"orders" => 1}})
      else
        item_agg_coll["#{self.item_id}"].merge!({"orders" => item_agg_coll["#{self.item_id}"]["orders"].to_i + 1})
      end
      agg_imp_by_item.agg_coll = item_agg_coll
      agg_imp_by_item.save!
    else
      time = self.order_date.to_time.utc rescue Time.now
      date = time.to_date rescue ""

      agg_imp = AggregatedImpression.where(:agg_date => date, :ad_id => nil, :for_pub => true).last
      if agg_imp.blank?
        agg_imp = AggregatedImpression.new(:agg_date => date, :ad_id => nil, :for_pub => true, :total_orders => 1)
        agg_imp.save!
      else
        agg_imp.total_orders = agg_imp.total_orders.to_i + 1
        agg_imp.save!
      end
    end
  end
end
