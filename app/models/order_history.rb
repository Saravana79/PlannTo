class OrderHistory < ActiveRecord::Base
  validates :order_date, :total_revenue, :vendor_ids, presence: true

  belongs_to :add_impression, :foreign_key => :impression_id
  belongs_to :vendor, :foreign_key => :vendor_ids
  belongs_to :payment_report
  belongs_to :advertisement
  after_save :create_record_in_m_order_history

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
    users = [["pla04", "cyn04"]]
    users.each do |user|
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

        order_history = OrderHistory.find_or_initialize_by_order_date_and_impression_id_and_total_revenue(date.to_time, impression_id, revenue)
        order_history.vendor_ids = 9882
        order_history.product_price = price
        order_history.no_of_orders = 1
        order_history.order_status = "Validated"
        order_history.payment_status = "Validated"

        impression = AddImpression.where(:id => impression_id).last
        unless impression.blank?
          order_history.item_id = impression.item_id
          product = impression.item
          order_history.item_name = product.name unless product.blank?
          order_history.sid = impression.sid
          order_history.advertisement_id = impression.advertisement_id
          order_history.publisher_id = impression.publisher_id
        end
        order_history.save!
      end
    end
  end

  def self.generate_filename(user, date)
    date_int = date.strftime("%Y%m%d")
    filename = "#{user[0]}-21-earnings-report-#{date_int}.xml.gz"
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

      impression = csv_detail[headers.index("AffExtParam2")].blank? ? nil : AddImpression.where(:id => csv_detail[headers.index("AffExtParam2")]).last

      unless impression.blank?
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
    imp = AdImpression.where(:_id => imp_id).last
    unless imp.blank?
      m_order_history = imp.m_order_histories.where(:order_history_id => self.id).last
      unless m_order_history.blank?
        m_order_history.total_revenue = self.total_revenue
        m_order_history.save
      else
        imp.m_order_histories << MOrderHistory.new(:order_history_id => self.id, :total_revenue => self.total_revenue)
      end
    end
  end
end
