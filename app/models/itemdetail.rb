class Itemdetail < ActiveRecord::Base

  has_one :vendor, :primary_key => "site", :foreign_key => "id"
  has_one :image, as: :imageable

  belongs_to :item, :foreign_key => "itemid"

  def self.get_item_details(item_id, vendor_ids)
    item_id = sanitize(item_id)
    # vendor_id = sanitize(vendor_id)
    find_by_sql("SELECT itemdetails.*, items.imageurl, items.type FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE items.id = #{item_id}
                 and itemdetails.isError = 0 and site in (#{vendor_ids.map(&:inspect).join(', ')}) ORDER BY itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0
                 else itemdetails.cashback end) asc")
  end

  def self.get_item_details_by_item_ids(item_ids, vendor_ids)
    # status_condition = vendor_ids.count > 1 ? " and itemdetails.status in (1,3,2)" : ""
    status_condition = " and itemdetails.status in (1,3)"
    # vendor_id = sanitize(vendor_id)


    find_by_sql("SELECT itemdetails.*, items.imageurl, items.type FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE items.id in (#{item_ids.map(&:inspect).join(', ')})
                 and itemdetails.isError =0 #{status_condition} and site in (#{vendor_ids.blank? ? "''" : vendor_ids.map(&:inspect).join(', ')}) ORDER BY field(items.id, #{item_ids.map(&:inspect).join(', ')}), itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else
                 itemdetails.cashback end) asc")
  end

  def self.get_item_detail_with_lowest_price(item_id)
    # item_id = sanitize(item_id)
    find_by_sql("SELECT itemdetails.*, items.imageurl, items.type FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE items.id = #{item_id}
                 and itemdetails.isError = 0 ORDER BY itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0
                 else itemdetails.cashback end) asc")
  end

  def self.get_item_details_by_item_ids_count(item_ids, vendor_ids, items, publisher, status, more_vendors, p_item_ids=[])
    @item_details = []
    if item_ids.count > 1
      @item_details = Itemdetail.get_item_details_by_item_ids(item_ids, vendor_ids).group_by { |each_rec| each_rec.itemid }
    elsif item_ids.count == 1
      items = Item.get_related_items_if_one_item(items, publisher, status) #if (activate_tab && items.count == 1)
      item_ids = items.map(&:id)
      @item_details = Itemdetail.get_item_details_by_item_ids(item_ids, vendor_ids).group_by { |each_rec| each_rec.itemid }
      # @item_details = Itemdetail.get_item_details(item_ids.first, vendor_ids).group_by { |each_rec| each_rec.itemid }
    end

    if (more_vendors == "true" || p_item_ids.count > 1)
      @item_details = @item_details.blank? ? [] : Itemdetail.get_sort_by_vendor(@item_details, vendor_ids).flatten.uniq(&:url)
    else
      @item_details = @item_details.is_a?(Hash) ? @item_details.values.flatten : @item_details.flatten
    end
  end

  def vendor_name
    return "" if vendor.nil?
    return vendor.name
  end

  def image_url
    return "" if vendor.nil?
    return vendor.imageurl
  end
  
  def self.display_item_details(item)
if ((item.status ==1 || item.status ==3)  && !item.IsError?)
    return true
    else
    return false
    end
  end
  

  def self.display_availability_detail(item)

    if(item.status  == 1)
       "Available"
    elsif(item.status  == 2)
      "Out of Stock"
    elsif(item.status  == 3) 
      "Pre-Order"
    end
  end

   def self.display_shipping_detail(item)
    unless item.shipping.blank?
      unit = ""
      if item.shippingunit == 1
        unit = "hours"
      elsif item.shippingunit == 2
        unit = "Business days"
      elsif item.shippingunit == 3
        unit = "Months"
      elsif item.shippingunit == 4
        unit = "Years"
      end
      "#{item.shipping} #{unit}"
    else
      if item.status == 3
        "[Pre-Order]"
      else        
        "N/A"
      end
    end

  end

  def self.display_price_detail(item)
    pre_order_val = item.status == 3 ? "Pre-Order" : ""
    if(!item.cashback.nil? && item.cashback != 0.0)
      item.price == 0.0 ? pre_order_val :  Itemdetail.number_to_indian_currency((item.price - item.cashback).to_f.round(2)).to_s
    else
    item.price == 0.0 ? pre_order_val :  Itemdetail.number_to_indian_currency(item.price.to_f.round(2)).to_s
    end

  end
  def self.number_to_indian_currency(number)
    if number
      string = number.to_s
      number = string.to_s.gsub(/(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?/, "\\1,")
    end
    "Rs #{number}"
  end

  def self.get_sort_by_vendor(item_details, vendor_ids)
    exp_result = {}
    return_val = []

    item_details.keys.each do |each_key|
      splt_item_details = item_details[each_key]
      exp_result[each_key] = splt_item_details.group_by {|splt_each_item| splt_each_item.site.to_i}
    end

    item_keys = exp_result.keys
    max_count = exp_result.map {|_, s| s.map {|_, x| x.count}}.flatten.max

    vendor_orders = vendor_ids

    [*0...max_count].each do |each_val|
      item_keys.each do |each_item|
        vendor_orders.each do |each_vendor|
          unless exp_result[each_item.to_i][each_vendor].blank?
            item_detail = exp_result[each_item][each_vendor][each_val]
            return_val << item_detail unless item_detail.blank?
          end
        end
      end
    end

    return_val
  end

  def self.get_where_to_buy_items(publisher, items, show_price, status, url, user, remote_ip, itemsaccess, url_params, plan_to_temp_user_id, is_test, winning_price_enc)
    country = ""
    tempitems = []
    impression_id = ""
    if (!publisher.nil? && publisher.id == 9 && country != "India")
      where_to_buy_items = []
      item = items[0]
      itemsaccess = "othercountry"
    elsif show_price != "false"
        where_to_buy_items, tempitems, item = Item.process_and_get_where_to_buy_items(items, publisher, status)
        main_item = item
        items = items - tempitems

        # for activate_tab users
        if (items.blank? && where_to_buy_items.blank?)
          item = main_item
          items = Item.where(:id => item.new_version_item_id)
          where_to_buy_items, tempitems, item = Item.process_and_get_where_to_buy_items(items, publisher, status)

          items = items - tempitems

          if (items.blank? && where_to_buy_items.blank?)
            item_ad_detail = main_item.item_ad_detail
            unless item_ad_detail.blank?
              items = Item.where(:id => item_ad_detail.old_version_id)
              where_to_buy_items, tempitems, item = Item.process_and_get_where_to_buy_items(items, publisher, status)
              items = items - tempitems
            end
          end
        end

        if (where_to_buy_items.empty?)
          itemsaccess = "emptyitems"
        end
        if is_test != "true"
          impression_id = AddImpression.add_impression_to_resque("pricecomparision", item.id, url, user, remote_ip, nil, itemsaccess, url_params,
                                                                  plan_to_temp_user_id, nil, winning_price_enc, nil)
        end
      else
        where_to_buy_items = []
        item, best_deals, impression_id = ArticleContent.get_best_deals(items.map(&:id).join(",").split(","), url, url_params, is_test, user, remote_ip, plan_to_temp_user_id)
        itemsaccess = "offers"
      end

    return where_to_buy_items, item, best_deals, impression_id
  end

  def self.amazon_price_update(actual_time)
    time = actual_time.to_time
    impression_date_condition = "impression_time > '#{time.beginning_of_day.strftime('%F %T')}' and impression_time < '#{time.end_of_day.strftime('%F %T')}'"
    query = "select distinct item_id from add_impressions where #{impression_date_condition}"

    add_impressions = Item.find_by_sql(query)
    item_ids = add_impressions.map(&:item_id)
    item_ids = item_ids.map {|item_id| item_id.to_i}

    splitted_array = item_ids.each_slice(30).to_a

    splitted_array.each do |spl_item_ids|
      item_details_query = "select * from itemdetails where site=9882 and itemid in (#{spl_item_ids.map(&:inspect).join(',')})"
      item_details = Itemdetail.find_by_sql(item_details_query)
      count = 0
      item_details.each do |item_detail|
        begin
          p Time.now
          url = item_detail.url
          asin = url[/.*\/dp\/(.*)/m,1]
          asin = asin.split("/")[0]
          p 1111111111
          p asin

          res = Amazon::Ecs.item_lookup("B00B70KYOO", {:response_group => 'Offers', :country => 'in'})
          p res.is_valid_request?
          if res.is_valid_request?
            item = res.first_item
            unless item.blank?
              p 22222
              offer_listing = item.get_element("Offers/Offer/OfferListing")
              if !offer_listing.blank?
                p current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                p saved_price = offer_listing.get_element("AmountSaved").get("FormattedPrice").gsub("INR ", "").gsub(",", "") rescue 0
                p saved_percentage = offer_listing.get("PercentageSaved") rescue 0
                p availability_str = offer_listing.get("Availability")

                status = case availability_str
                           when /Usually dispatched.*/ || /Usually ships.*/
                             1
                           when /Not yet released/ || /Not yet published/
                             3
                           when /This item is not stocked or has been discontinued/
                             4
                           when /Out of Stock/
                             2
                           else
                             4
                         end

                p mrp_price = current_price.to_f + saved_price.to_f
                item_detail.update_attributes!(:price => current_price, :status => status, :savepercentage => saved_percentage, :mrpprice => mrp_price)
              else
                item_detail.update_attributes!(:status => 2)
              end
            end
          end
        rescue Exception => e
          p "can't saved price details for #{item_detail.id}"
          p e.message
        end
        count+=1
        if count == 2
          p "ssllllllllllllllllllleeeeeeeeeeepppppppp"
          sleep 1.5
          count = 0
        end
      end
    end
  end


  def self.update_from_vendors(time)
    url = "http://www.mysmartprice.com/store_data/msp_master.xml"
    xml_data = Net::HTTP.get_response(URI.parse(url)).body
    data = XmlSimple.xml_in(xml_data)
    items = data["channel"][0]["item"]
    item_details = ActiveRecord::Base.connection.execute("update itemdetails set status = 4 where site = 26351")

    items.each do |item|
      begin
        p "--- Started Process #{url} ---"
        title = item["title"][0]
        product_type = item["product_type"][0].to_s.split(">")[1].to_s.strip
        url = item["link"][0]
        price = item["price"][0]
        image_url = item["image_link"][0]
        itemtype_hash = {"mobile" => 6, "laptops" => 23, "tablet" => 13}
        filename = image_url.split("/").last
        filename = filename == "noimage.jpg" ? nil : filename
        source_item = Sourceitem.find_or_initialize_by_url(url)
        if source_item.new_record?
          source_item.update_attributes(:name => title, :status => 1, :urlsource => "Mysmartprice", :itemtype_id => itemtype_hash[product_type], :created_by => "System", :verified => false)
        elsif source_item.verified && !source_item.matchitemid.blank?
          item_detail = Itemdetail.find_or_initialize_by_url(url)
          if item_detail.new_record?
            item_detail.update_attributes!(:ItemName => title, :itemid => source_item.id, :url => url, :price => price, :status => 1, :last_verified_date => Time.now, :site => 26351, :iscashondeliveryavailable => false, :isemiavailable => false, :Image => filename)
            image = nil
          else
            image = item_detail.Image
            item_detail.update_attributes!(:price => price, :status => 1, :last_verified_date => Time.now, :Image => filename)
          end
          p filename
          if image.blank? && !image_url.blank? && !filename.blank?
            p "image----------------------------"
            image = item_detail.build_image
            tempfile = open(image_url)
            avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile})
            avatar.original_filename = filename
            image.avatar = avatar
            image.save
          end
        end
      rescue Exception => e
        p "-------------------- There was a problem while processing itemdetail item #{url} => #{e.message}-----------------"
      end
      p "--- End Process #{url} ---"
    end
  end
end
