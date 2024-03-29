class Itemdetail < ActiveRecord::Base

  has_one :vendor, :primary_key => "site", :foreign_key => "id"
  has_one :image, as: :imageable

  attr_accessor :skip_after_save, :match_type, :type, :imageurl

  belongs_to :item, :foreign_key => "itemid"

  after_save :update_last_verified_date

  def self.get_item_details(item_id, vendor_ids)
    item_id = sanitize(item_id)
    # vendor_id = sanitize(vendor_id)
    find_by_sql("SELECT itemdetails.*, items.imageurl, items.type FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE items.id = #{item_id}
                 and itemdetails.isError = 0 and site in (#{vendor_ids.map(&:inspect).join(', ')}) ORDER BY itemdetails.status asc, sort_priority desc, (itemdetails.price - case when itemdetails.cashback is null then 0
                 else itemdetails.cashback end) asc")
  end

  def self.get_item_details_by_item_ids(item_ids, vendor_ids, fashion_id=nil, ad=nil, skip_limit_in_query=false)
    # status_condition = vendor_ids.count > 1 ? " and itemdetails.status in (1,3,2)" : ""
    vendor_ids = vendor_ids.compact

    vendor_ids_condition = vendor_ids.blank? ? "" : " and site in (#{vendor_ids.map(&:inspect).join(', ')})"

    item_ids = item_ids.compact
    status_condition = " and itemdetails.status in (1,3)"
    # vendor_id = sanitize(vendor_id)

    item_ids = item_ids.compact
    return [] if item_ids.blank?

    if (!fashion_id.blank? || (!ad.blank? && ad.sort_type == "random"))
      order_by_condition = " order by rand(), sort_priority desc limit 12"
    else
      limit_condition = skip_limit_in_query ? "" : " limit 12"
      order_by_condition = "ORDER BY field(items.id, #{item_ids.map(&:inspect).join(', ')}), itemdetails.status asc, sort_priority desc, (itemdetails.price - case when itemdetails.cashback is null then 0 else
                 itemdetails.cashback end) asc #{limit_condition}"
    end

    find_by_sql("SELECT itemdetails.*, items.imageurl, items.type FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE items.id in (#{item_ids.map(&:inspect).join(', ')})
                 and itemdetails.isError =0 #{status_condition} #{vendor_ids_condition} #{order_by_condition}")
  end

  def self.get_item_details_by_item_ids_for_women_widget(item_ids, vendor_ids, fashion_id=nil, ad=nil)
    # status_condition = vendor_ids.count > 1 ? " and itemdetails.status in (1,3,2)" : ""
    vendor_ids = vendor_ids.compact
    item_ids = item_ids.compact
    status_condition = " and itemdetails.status in (1,3)"
    # vendor_id = sanitize(vendor_id)

    item_ids = item_ids.compact
    return [] if item_ids.blank?

    if (!fashion_id.blank? || (!ad.blank? && ad.sort_type == "random"))
      order_by_condition = " order by rand(), sort_priority desc limit 12"
    else
      order_by_condition = "ORDER BY field(items.id, #{item_ids.map(&:inspect).join(', ')}), itemdetails.status asc, sort_priority desc, (itemdetails.price - case when itemdetails.cashback is null then 0 else
                 itemdetails.cashback end) asc limit 12"
    end

    find_by_sql("SELECT itemdetails.*, itemdetails.item_details_id as itemdetail_id, itemdetails.ItemName as name, itemdetails.Image as image_name,  items.imageurl, items.type FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE items.id in (#{item_ids.map(&:inspect).join(', ')})
                 and itemdetails.isError =0 #{status_condition} and site in (#{vendor_ids.blank? ? "''" : vendor_ids.map(&:inspect).join(', ')}) #{order_by_condition}")
  end

  def self.get_item_details_count_by_item_ids(item_ids, vendor_ids)
    # status_condition = vendor_ids.count > 1 ? " and itemdetails.status in (1,3,2)" : ""
    status_condition = " and itemdetails.status in (1,3)"
    # vendor_id = sanitize(vendor_id)

    item_ids = item_ids.compact
    return [] if item_ids.blank?

    find_by_sql("SELECT count(*) as count FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE items.id in (#{item_ids.to_a.map(&:inspect).join(', ')})
                 and itemdetails.isError =0 #{status_condition} and site in (#{vendor_ids.blank? ? "''" : vendor_ids.map(&:inspect).join(', ')})")
  end

  def self.get_item_detail_with_lowest_price(item_id)
    # item_id = sanitize(item_id)
    find_by_sql("SELECT itemdetails.*, items.imageurl, items.type FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE items.id = #{item_id}
                 and itemdetails.isError = 0 ORDER BY itemdetails.status asc, sort_priority desc, (itemdetails.price - case when itemdetails.cashback is null then 0
                 else itemdetails.cashback end) asc")
  end

  def self.get_item_details_by_item_ids_count(item_ids, vendor_ids, items, publisher, status, more_vendors, p_item_ids=[], ad=nil, skip_limit_in_query=false)
    item_details = []
    if item_ids.count > 1
      item_details = Itemdetail.get_item_details_by_item_ids(item_ids, vendor_ids, nil, ad, skip_limit_in_query).group_by { |each_rec| each_rec.itemid }
    elsif item_ids.count == 1
      items = Item.get_related_items_if_one_item(items, publisher, status) #if (activate_tab && items.count == 1)
      item_ids = items.map(&:id)
      item_details = Itemdetail.get_item_details_by_item_ids(item_ids, vendor_ids, nil, ad, skip_limit_in_query).group_by { |each_rec| each_rec.itemid }
      # item_details = Itemdetail.get_item_details(item_ids.first, vendor_ids).group_by { |each_rec| each_rec.itemid }
    end

    if (more_vendors == "true" || vendor_ids.count > 1)
      item_details = item_details.blank? ? [] : Itemdetail.get_sort_by_vendor(item_details, vendor_ids).flatten.uniq(&:url)
    else
      group_ids = Itemdetail.get_group_ids_from_item_ids(item_ids) rescue {}

      if item_details.is_a?(Hash)
        item_details = Itemdetail.get_sort_by_group(item_details, group_ids)
      else
        item_details = item_details.flatten
      end
    end
    item_details
  end

  def self.get_group_ids_from_item_ids(item_ids)
    group_ids = {}
    items = Item.find_by_sql("select id, group_id from items where id in (#{item_ids.map(&:inspect).join(', ')}) group by id")
    items.each do |each_item|
      group_ids.merge!(each_item.id => each_item.group_id)
    end
    group_ids
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
    if ((item.status ==1 || item.status ==3) && !item.IsError?)
      return true
    else
      return false
    end
  end


  def self.display_availability_detail(item)

    if (item.status == 1)
      "Available"
    elsif (item.status == 2)
      "Out of Stock"
    elsif (item.status == 3)
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
    if (!item.cashback.nil? && item.cashback != 0.0)
      item.price == 0.0 ? pre_order_val : Itemdetail.number_to_indian_currency((item.price - item.cashback).to_f.round(2)).to_s
    else
      item.price == 0.0 ? pre_order_val : Itemdetail.number_to_indian_currency(item.price.to_f.round(2)).to_s
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
      exp_result[each_key] = splt_item_details.group_by { |splt_each_item| splt_each_item.site.to_i }
    end

    item_keys = exp_result.keys
    max_count = exp_result.map { |_, s| s.map { |_, x| x.count } }.flatten.max

    vendor_orders = vendor_ids

    return [] if max_count == 0 || max_count.blank?

    [*0...max_count].each do |each_val|
      item_keys.each do |each_item|
        vendor_orders.each do |each_vendor|
          unless exp_result[each_item.to_i][each_vendor.to_i].blank?
            item_detail = exp_result[each_item][each_vendor.to_i][each_val]
            return_val << item_detail unless item_detail.blank?
          end
        end
      end
    end

    return_val
  end

  def self.get_sort_by_item(item_details)
    item_details = item_details.group_by { |val| val.itemid }
    return_val = []

    item_keys = item_details.keys
    max_count = item_details.map { |_, x| x.count }.flatten.max

    [*0...max_count].each do |each_val|
      item_keys.each do |each_item|
        unless item_details[each_item.to_i][each_val].blank?
          return_val << item_details[each_item.to_i][each_val]
        end
      end
    end

    return_val
  end

  def self.get_sort_by_group(item_details, group_ids)
    i = 0
    group_ids.each do |k,v|
      i += 1
      if v.blank?
        group_ids[k] = "temp_id_#{i}"
      end
    end

    item_details = item_details.values.flatten
    item_details_hash = item_details.group_by { |each_val| group_ids[each_val.itemid] }

    return_val = []

    item_keys = item_details_hash.keys
    max_count = item_details_hash.map { |_, s| s.count }.flatten.max

    [*0...max_count.to_i].each do |each_val|
      item_keys.each do |group_id|
        item_detail = item_details_hash[group_id][each_val]
        return_val << item_detail unless item_detail.blank?
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
      if (items.blank? && where_to_buy_items.blank? && !main_item.blank?)
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
        impression_id = AddImpression.add_impression_to_resque("pricecomparision", item.blank? ? nil : item.id, url, user, remote_ip, nil, itemsaccess, url_params,
                                                               plan_to_temp_user_id, nil, winning_price_enc, nil)
      end
    else
      where_to_buy_items = []
      item, best_deals, impression_id = ArticleContent.get_best_deals(items.map(&:id).join(",").split(","), url, url_params, is_test, user, remote_ip, plan_to_temp_user_id)
      itemsaccess = "offers"
    end

    return where_to_buy_items, item, best_deals, impression_id
  end

  def self.get_where_to_buy_items_using_vendor(publisher, items, show_price, status, old_where_to_buy_items=[], vendor_ids=[], sortbyitem = false)
    country = ""
    tempitems = []
    impression_id = ""
    if (!publisher.nil? && publisher.id == 9 && country != "India")
      where_to_buy_items = []
      item = items[0]
      itemsaccess = "othercountry"
    elsif show_price != "false"
      where_to_buy_items, tempitems, item = Item.process_and_get_where_to_buy_items_using_vendor_and_items(items, publisher, status, vendor_ids)
      main_item = item
      items = items - tempitems

      # for activate_tab users
      if (items.blank? && where_to_buy_items.blank? && !main_item.blank?)
        item = main_item
        items = Item.where(:id => item.new_version_item_id)
        where_to_buy_items, tempitems, item = Item.process_and_get_where_to_buy_items_using_vendor_and_items(items, publisher, status, vendor_ids)

        items = items - tempitems

        if (items.blank? && where_to_buy_items.blank?)
          item_ad_detail = main_item.item_ad_detail
          unless item_ad_detail.blank?
            items = Item.where(:id => item_ad_detail.old_version_id)
            where_to_buy_items, tempitems, item = Item.process_and_get_where_to_buy_items_using_vendor_and_items(items, publisher, status, vendor_ids)
            items = items - tempitems
          end
        end
      end
    end

    if !old_where_to_buy_items.blank?
      where_to_buy_items = where_to_buy_items.shuffle
      where_to_buy_items = old_where_to_buy_items + where_to_buy_items
    end

    if ((!vendor_ids.blank?) && (!sortbyitem))
      item_details = where_to_buy_items.group_by { |item_detail| item_detail.itemid }
      where_to_buy_items = Itemdetail.get_sort_by_vendor(item_details, vendor_ids)
    elsif !where_to_buy_items.blank?
      where_to_buy_items = Itemdetail.get_sort_by_item(where_to_buy_items)
    end

    return where_to_buy_items
  end

  def self.amazon_price_update(actual_time)
    time = actual_time.to_time
    impression_date_condition = "impression_time > '#{time.beginning_of_day.strftime('%F %T')}' and impression_time < '#{time.end_of_day.strftime('%F %T')}'"
    query = "select distinct item_id from add_impressions1 where #{impression_date_condition}"

    add_impressions = Item.find_by_sql(query)
    item_ids = add_impressions.map(&:item_id)
    item_ids = item_ids.map { |item_id| item_id.to_i }

    splitted_array = item_ids.each_slice(30).to_a

    splitted_array.each do |spl_item_ids|
      item_details_query = "select * from itemdetails where site=9882 and itemid in (#{spl_item_ids.map(&:inspect).join(',')})"
      item_details = Itemdetail.find_by_sql(item_details_query)
      count = 0
      item_details.each do |item_detail|
        begin
          url = item_detail.url
          asin = url[/.*\/dp\/(.*)/m, 1]
          asin = asin.split("/")[0]

          # res = Amazon::Ecs.item_lookup("B00B70KYOO", {:response_group => 'Offers', :country => 'in'})
          res = Amazon::Ecs.item_lookup(asin, {:response_group => 'Offers', :country => 'in'})
          if res.is_valid_request?
            item = res.first_item
            unless item.blank?
              offer_listing = item.get_element("Offers/Offer/OfferListing")
              offer_summary = each_item.get_element("OfferSummary")
              if !offer_listing.blank?
                begin
                  current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",", "")
                rescue Exception => e
                  current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",", "")
                end
                saved_price = offer_listing.get_element("AmountSaved").get("FormattedPrice").gsub("INR ", "").gsub(",", "") rescue 0
                saved_percentage = offer_listing.get("PercentageSaved") rescue 0
                availability_str = offer_listing.get("Availability")

                if availability_str.blank? && !offer_summary.blank?
                  current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",", "") rescue "" if current_price.blank?

                  total_new = offer_summary.get("TotalNew").to_i

                  if total_new > 0
                    status = 1
                  else
                    status = 0
                  end
                else
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
                end

                mrp_price = current_price.to_f + saved_price.to_f
                item_detail.update_attributes!(:price => current_price, :status => status, :savepercentage => saved_percentage, :mrpprice => mrp_price, :last_verified_date => Time.now)
              elsif !offer_summary.blank?
                current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",", "") rescue ""

                total_new = offer_summary.get("TotalNew").to_i

                if total_new > 0
                  status = 1
                else
                  status = 0
                end

                item_detail.update_attributes!(:price => current_price, :status => status, :last_verified_date => Time.now)
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


  def self.update_from_vendors(time=Time.now)
    return if $redis.get("update_itemdetails_from_vendors_is_running").to_i == 0
    $redis.set("update_itemdetails_from_vendors_is_running", 1)
    $redis.expire("update_itemdetails_from_vendors_is_running", 40.minutes)

    url = "http://www.mysmartprice.com/store_data/msp_master.xml"
    top_product_ids = $redis.get("mysmartprice_top_products")
    top_product_ids = top_product_ids.to_s.split(",")
    top_product_ids = top_product_ids.map(&:to_i)

    exclued_item_ids = [28712] #only integer, add exclued item - additional_details

    top_product_ids = top_product_ids - exclued_item_ids

    # xml_data = Net::HTTP.get_response(URI.parse(url)).body
    # data = XmlSimple.xml_in(xml_data)
    # items = data["channel"][0]["item"]

    doc = Nokogiri::XML(open(url))
    node = doc.elements.first

    node.xpath("//item").each do |item|
      begin
        p "--- Started Process #{url} ---"
        id = item.at_xpath("g:id").content rescue nil
        id = id.to_s.downcase rescue nil
        title = item.at_xpath("title").content rescue ""
        product_type = item.at_xpath("g:product_type").content rescue ""
        product_type = product_type.to_s.split(">")[1].to_s.strip
        url = item.at_xpath("link").content rescue ""
        price = item.at_xpath("g:price").content rescue ""
        image_url = item.at_xpath("g:image_link").content rescue ""

        itemtype_hash = {"mobile" => 6, "laptops" => 23, "tablet" => 13, "lenses" => 20, "digital-camera" => 12, "digital-slr-camera" => 12}
        filename = image_url.split("/").last
        filename = filename == "noimage.jpg" ? nil : filename

        unless filename.blank?
          name = filename.to_s.split(".")
          name = name[0...name.size-1]
          name = name.join(".") + ".jpeg"
          filename = name
        end

        itemtype_id = itemtype_hash[product_type]

        if itemtype_id.blank?
          next
        end

        have_to_create_image = false
        if id.blank?
          @item_detail = Itemdetail.find_or_initialize_by_url(url)
        else
          @item_detail = Itemdetail.find_or_initialize_by_additional_details(id)
          @item_detail = Itemdetail.find_or_initialize_by_url(url) if @item_detail.blank?
        end

        if !@item_detail.new_record?
          have_to_create_image = @item_detail.Image.blank? ? true : false
          status = [6, 13].include?(itemtype_id) && !top_product_ids.include?(id.to_i) ? 6 : 1
          @item_detail.update_attributes!(:price => price, :status => status, :last_verified_date => Time.now, :iscashondeliveryavailable => false, :isemiavailable => false, :IsError => false, :additional_details => id)
        else
          source_item = Sourceitem.find_or_initialize_by_url(url)
          if source_item.new_record?
            source_item.update_attributes(:name => title, :status => 1, :urlsource => "Mysmartprice", :itemtype_id => itemtype_id, :created_by => "System", :verified => false, :additional_details => id)
          elsif source_item.verified && !source_item.matchitemid.blank?
            status = [6, 13].include?(itemtype_id) && !top_product_ids.include?(id.to_i) ? 6 : 1
            @item_detail.update_attributes!(:ItemName => title, :itemid => source_item.matchitemid, :url => url, :price => price, :status => status, :last_verified_date => Time.now, :site => 26351, :iscashondeliveryavailable => false, :isemiavailable => false, :IsError => false, :additional_details => id)
            have_to_create_image = true
          end
        end

        if have_to_create_image && !image_url.blank? && !filename.blank?
          p "image----------------------------"
          @image = @item_detail.build_image
          # tempfile = open(image_url)
          # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile})
          # avatar.original_filename = filename

          safe_thumbnail_url = URI.encode(URI.decode(image_url))
          extname = File.extname(safe_thumbnail_url).delete("%")
          basename = File.basename(safe_thumbnail_url, extname).delete("%")
          file = Tempfile.new([basename, extname])
          file.binmode
          open(URI.parse(safe_thumbnail_url), :allow_redirections => :all) do |data|
            file.write data.read
          end
          file.rewind

          avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file, :type => 'image/jpeg'})
          avatar.original_filename = filename

          @image.avatar = avatar
          if @image.save
            @item_detail.update_attributes(:Image => filename)
          end
        end

      rescue Exception => e
        p "-------------------- There was a problem while processing itemdetail item #{url} => #{e.message}-----------------"
      end
      p "--- End Process #{url} ---"
    end

    ActiveRecord::Base.connection.execute("update itemdetails set status = 4 where site = 26351 and last_verified_date < '#{1.day.ago}'")

    # Update item details for item
    Resque.enqueue(ItemUpdate, "update_item_details", Time.zone.now)
    $redis.set("update_itemdetails_from_vendors_is_running", 0)
  end

  def self.update_from_vendors_flipkart(time=Time.now)
    url = "https://affiliate-api.flipkart.net/affiliate/api/Saravanapl.xml"
    response = RestClient.get(url)
    c_doc = Nokogiri::XML(response.body)
    c_node = c_doc.elements.first
    types = ["mobiles", "tablets", "cameras", "laptops"]
    urls_for_access = []

    c_node.xpath("//entry").each_with_index do |each_node, inx|
      next if inx == 0
      resource_name = each_node.at_xpath("value").at_xpath("resourceName").content rescue ""
      if types.include?(resource_name)
        url_for_access = each_node.at_xpath("value").at_xpath("get").content rescue ""
        urls_for_access << {"type" => resource_name, "url" => url_for_access}
      end
    end

    urls_for_access.each do |each_hash|
      itemtype_hash = {"mobiles" => 6, "laptops" => 23, "tablets" => 13, "lenses" => 20, "cameras" => 12}
      itemtype_id = itemtype_hash[each_hash["type"]]
      begin
        Itemdetail.process_flipkart_items(each_hash["url"], itemtype_id) unless itemtype_id.blank?
      rescue Exception => e
        p "Error => #{e.message}"
      end
    end

    ActiveRecord::Base.connection.execute("update itemdetails set status = 4 where site = 9861 and last_verified_date < '#{1.day.ago}'")

    # Update item details for item
    Resque.enqueue(ItemUpdate, "update_item_details", Time.zone.now)
  end

  def self.process_flipkart_items(url, itemtype_id=nil)
    next_url = url
    total_item_count = 0
    page_count = 0
    begin
      page_count += 1
      now_url = next_url
      p "--- Started Process #{now_url} ---"
      response = RestClient.get(now_url, {'Fk-Affiliate-Id' => 'Saravanapl', 'Fk-Affiliate-Token' => '3c7efaaa5dfb4dbeb65dac26138aa155'})
      doc = Nokogiri::XML(response.body)
      node = doc.elements.first
      next_url = node.at_xpath("//nextUrl").content rescue ""
      item_count = 0
      begin
        node.xpath("//products//productInfoList").each do |item|
          begin
            item_count += 1
            total_item_count += 1
            id = item.at_xpath("productBaseInfo//productIdentifier//productId").content rescue nil
            id = id.to_s.downcase rescue nil
            item_info = item.at_xpath("productBaseInfo//productAttributes")
            title = item_info.at_xpath("title").content rescue ""
            url = item_info.at_xpath("productUrl").content rescue ""
            url = url.gsub(/&affid.*/, "") #remove affiliate id
            url = url.gsub("dl.", "www.").gsub("/dl/", "/")
            p "--- Processing url #{url} ---"
            price = item_info.at_xpath("sellingPrice//amount").content rescue ""
            image_url = item_info.at_xpath("imageUrls//entry//value").content rescue ""
            status = item_info.at_xpath("inStock").content rescue ""
            status = status == "true" ? 1 : 2
            cod = item_info.at_xpath("codAvailable").content rescue ""
            cod = cod == "true" ? true : false
            emi = item_info.at_xpath("emiAvailable").content rescue ""
            emi = emi == "true" ? true : false

            filename = image_url.split("/").last

            unless filename.blank?
              name = filename.to_s.split(".")
              name = name[0...name.size-1]
              name = name.join(".") + ".jpeg"
              filename = name
            end

            if itemtype_id.blank?
              next
            end

            have_to_create_image = false
            if id.blank?
              @item_detail = Itemdetail.find_or_initialize_by_url(url)
            else
              @item_detail = Itemdetail.find_or_initialize_by_additional_details(id)
              @item_detail = Itemdetail.find_or_initialize_by_url(url) if @item_detail.blank?
            end
            if !@item_detail.new_record?
              have_to_create_image = @item_detail.Image.blank? ? true : false
              @item_detail.update_attributes!(:price => price, :status => status, :last_verified_date => Time.now, :iscashondeliveryavailable => cod, :isemiavailable => emi, :IsError => false, :additional_details => id)
            else
              s_url = url.split("flipkart.com").last
              source_item = Sourceitem.find_or_initialize_by_url_and_urlsource(s_url, "Flipkart")
              if source_item.new_record?
                source_item.update_attributes(:name => title, :status => 1, :itemtype_id => itemtype_id, :created_by => "System", :verified => false, :additional_details => id)
              elsif source_item.verified && !source_item.matchitemid.blank?
                @item_detail.update_attributes!(:ItemName => title, :itemid => source_item.matchitemid, :url => url, :price => price, :status => status, :last_verified_date => Time.now, :site => 9861, :iscashondeliveryavailable => cod, :isemiavailable => emi, :IsError => false, :additional_details => id)
                have_to_create_image = true
              end
            end

            if have_to_create_image && !image_url.blank? && !filename.blank?
              p "image----------------------------"
              @image = @item_detail.build_image
              # tempfile = open(image_url)
              # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile})
              # avatar.original_filename = filename

              safe_thumbnail_url = URI.encode(URI.decode(image_url))
              extname = File.extname(safe_thumbnail_url).delete("%")
              basename = File.basename(safe_thumbnail_url, extname).delete("%")
              file = Tempfile.new([basename, extname])
              file.binmode
              open(URI.parse(safe_thumbnail_url), :allow_redirections => :all) do |data|
                file.write data.read
              end
              file.rewind

              avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file, :type => 'image/jpeg'})
              avatar.original_filename = filename

              @image.avatar = avatar
              if @image.save
                @item_detail.update_attributes(:Image => filename)
              end
            end
          rescue Exception => e
            p "Error while processing item"
          end
        end
      rescue Exception => e
        p "-------------------- There was a problem while processing itemdetail item #{url} => #{e.message}-----------------"
      end
      p "*************************************************************************** End Process url => #{now_url} : page_count => #{page_count} : count #{item_count} : total item count => #{total_item_count} ***************************************************************************"
      sleep(1.seconds)
    end while !next_url.blank?
  end

  def self.update_item_details_product_id(batch_size=1000)
    item_details_amazon_query = "select * from itemdetails where site=9882 and additional_details is null"

    page = 1
    begin
      item_details = Itemdetail.paginate_by_sql(item_details_amazon_query, :page => page, :per_page => batch_size)

      item_details.each do |item_detail|
        begin
          url = item_detail.url
          product_id = Itemdetail.get_vendor_product_id(url.to_s)

          item_detail.update_attributes(:additional_details => product_id) if !product_id.blank?
        rescue Exception => e
          p "error"
        end
      end

      page += 1
    end while !item_details.empty?

    item_details_flipkart_query = "select * from itemdetails where site=9861 and additional_details is null"

    page = 1
    begin
      item_details = Itemdetail.paginate_by_sql(item_details_flipkart_query, :page => page, :per_page => batch_size)

      uncategory_records = []
      item_details.each do |item_detail|
        begin
          url = item_detail.url
          product_id = Itemdetail.get_vendor_product_id(url.to_s)

          item_detail.update_attributes(:additional_details => product_id) if !product_id.blank?
        rescue Exception => e
          p "error"
        end
      end

      page += 1
    end while !item_details.blank?

    item_details_snapdeal_query = "select * from itemdetails where site=9874 and additional_details is null"

    page = 1
    begin
      item_details = Itemdetail.paginate_by_sql(item_details_snapdeal_query, :page => page, :per_page => batch_size)

      uncategory_records = []
      item_details.each do |item_detail|
        begin
          url = item_detail.url
          product_id = Itemdetail.get_vendor_product_id(url.to_s)

          item_detail.update_attributes(:additional_details => product_id) if !product_id.blank?
        rescue Exception => e
          p "error"
        end
      end

      page += 1
    end while !item_details.blank?
  end

  def self.get_vendor_product_id(url)
    if url.include?("amazon.in")
      asin = url[/.*\/dp\/(.*)/m, 1]
      asin = asin.split("/")[0]
      asin.to_s.downcase
    elsif url.include?("flipkart.com")
      pid = FeedUrl.get_value_from_pattern(url.to_s, "pid=<pid>", "<pid>")
      pid = pid.split("&")[0] if !pid.blank?
      pid.to_s.downcase
    elsif url.include?("snapdeal.com")
      pid = FeedUrl.get_value_from_pattern(url.to_s, "/<pid>", "<pid>")
      if !pid.blank?
        pid = pid.split("&")[0]
        pid = nil if !pid.match(/\D/).blank?
        pid
      end
    else
      nil
    end
  end

  def self.update_itemdetails_from_auto()
    car_item_type = Itemtype.where(:itemtype => "CarAccessory").last
    if car_item_type.blank?
      car_item_type = Itemtype.new({"itemtype" => "CarAccessory", "description" => "Car Accessories", "created_by" => 1, "updated_by" => nil, "creator_ip" => nil, "updater_ip" => nil, "orderby" => 1})
      car_item_type.save!
    end
    car_item_type_tag = ItemtypeTag.where(:name => "CarAccessory").last
    if car_item_type_tag.blank?
      car_item_type_tag = ItemtypeTag.new(:name => "CarAccessory", :itemtype_id => 17, :imageurl => "car_accessory.jpeg", :created_by => 1, :status => 1)
      car_item_type_tag.save!
    end

    bike_item_type = Itemtype.where(:itemtype => "MotorbikeAccessory").last
    if bike_item_type.blank?
      bike_item_type = Itemtype.new({"itemtype" => "MotorbikeAccessory", "description" => "Motorbike Accessories", "created_by" => 1, "updated_by" => nil, "creator_ip" => nil, "updater_ip" => nil, "orderby" => 1})
      bike_item_type.save!
    end
    bike_item_type_tag = ItemtypeTag.where(:name => "MotorbikeAccessory").last
    if bike_item_type_tag.blank?
      bike_item_type_tag = ItemtypeTag.new(:name => "MotorbikeAccessory", :itemtype_id => 17, :imageurl => "motorbike_accessory.jpeg", :created_by => 1, :status => 1)
      bike_item_type_tag.save!
    end

    # xml_url = "/home/sivakumar/skype/in_auto_all"
    # xml_url = "/home/sivakumar/skype/temp_in_auto_all.xml"

    xml_url = "http://cdn1.plannto.com/test_folder/in_auto_all"
    doc = Nokogiri::XML(open(xml_url))
    node = doc.elements.first
    vendor_id = "9882"

    node.xpath("//item_data").each do |each_item|
      begin
        item_basic_data = each_item.at_xpath("item_basic_data")
        asin = item_basic_data.at_xpath("item_unique_id").content rescue ""
        item_name = item_basic_data.at_xpath("item_name").content rescue ""
        item_name = CGI.unescapeHTML item_name
        description = item_basic_data.at_xpath("item_short_desc").content rescue ""
        url = item_basic_data.at_xpath("item_page_url").content rescue ""
        url = CGI.unescapeHTML url
        url = url.gsub(/\/ref.*/, "")
        image_url = item_basic_data.at_xpath("item_image_url_large").content rescue ""
        price = item_basic_data.at_xpath("item_price").content rescue ""

        category = each_item.at_xpath("merch_cat_list//merch_cat_path").content rescue ""
        categories = category.to_s.split("/")
        item_type = categories[2].to_s.downcase
        case item_type
          when /car/
            itemtype_now = car_item_type
            itemtype_tag = car_item_type_tag
          when /bike/
            itemtype_now = bike_item_type
            itemtype_tag = bike_item_type_tag
        end
        itemname = categories.last.to_s.downcase
        next if itemtype_tag.blank? || itemname.blank?

        # item = Item.where(:itemtype_id => itemtype.id, :name => itemname).last
        # if item.blank?
        #   item = Item.new(:itemtype_id => itemtype.id, :name => itemname, :status => 1, :imageurl => "#{itemname}.jpeg")
        #   item.type = itemtype.itemtype
        #   item.save!
        # end


        availability_str = item_basic_data.at_xpath("item_inventory").content rescue ""
        status = case availability_str.to_s
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

        if asin.blank?
          item_detail = Itemdetail.where(:url => url).first
        else
          item_detail = Itemdetail.where(:additional_details => asin).first
          item_detail = Itemdetail.where(:url => url).first if item_detail.blank?
        end

        if item_detail.blank?
          item_detail = Itemdetail.new(:itemid => itemtype_tag.id, :ItemName => item_name, :url => url, :price => price, :status => status, :iscashondeliveryavailable => false, :isemiavailable => false, :IsError => false, :additional_details => asin, :site => "9882", :description => description, :category => category)
          item_detail.save!
        else
          item_detail.update_attributes!(:itemid => itemtype_tag.id, :ItemName => item_name, :price => price, :status => status, :iscashondeliveryavailable => false, :isemiavailable => false, :IsError => false, :additional_details => asin, :site => "9882", :description => description, :category => category)
        end

        next if !item_detail.image.blank?

        filename = image_url.to_s.split("/").last
        filename = filename == "noimage.jpg" ? nil : filename

        filename = filename.gsub("%", "_")

        unless filename.blank?
          name = filename.to_s.split(".")
          name = name[0...name.size-1]
          name = name.join(".") + ".jpeg"
          filename = name
        end

        if !item_detail.blank? && !image_url.blank? && !filename.blank?
          p "image----------------------------"
          @image = item_detail.build_image
          # tempfile = open(image_url)
          # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile})
          # avatar.original_filename = filename

          safe_thumbnail_url = URI.encode(URI.decode(image_url))
          extname = File.extname(safe_thumbnail_url).delete("%")

          basename = File.basename(safe_thumbnail_url, extname).delete("%")

          file = Tempfile.new([basename, extname])
          file.binmode
          open(URI.parse(safe_thumbnail_url), :allow_redirections => :all) do |data|
            file.write data.read
          end
          file.rewind

          avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file, :type => 'image/jpeg'})
          avatar.original_filename = filename

          @image.avatar = avatar
          if @image.save
            item_detail.update_attributes(:Image => filename)
          end
        end
      rescue Exception => e
        p "Error While processing => #{e.message}"
      end
    end
  end

  def get_vendor_name
    return_val = nil
    begin
      vendor_id = self.site
      vendor = Vendor.where(:id => vendor_id).first
      vendor_name = vendor.vendor_detail.name rescue ""
      return_val = vendor_name
    rescue Exception => e
      p "Error while getting vendor name"
      return_val = vendor_name
    end
    return_val
  end

  def itemtype_id
    self.item.itemtype_id rescue ""
  end

  def self.get_auto_categories
    # car_item_type = Itemtype.where(:itemtype => "CarAccessory").last
    # bike_item_type = Itemtype.where(:itemtype => "MotorbikeAccessory").last
    # car_item_type_items = Item.where(:itemtype_id => car_item_type.id).select("distinct name").map(&:name)
    # bike_item_type_items = Item.where(:itemtype_id => bike_item_type.id).select("distinct name").map(&:name)
    # return {car_item_type.itemtype => car_item_type_items, bike_item_type.itemtype => bike_item_type_items}
    return {"Car" => {"Car Care Exterior (Shampoos, Polishes, Waxes)" => "Paint & Exterior Care", "Car Care Interior (Dashboard & Trim care, Cleaners)" => "Interior Care", "Car Parts (Filters, Bulbs, wiper blades)" => "Car Parts", "Car Electronics (Audio, GPS, Chargers)" => "Car Electronics", "Car Accessories (Covers, Mats, Freshners)" => "Car Accessories"}, "Bike" => {"Helmets (Flip-up, Full face, Open face)" => "Helmets", "Gloves" => "Gloves", "Jackets" => "Jackets", "Head & Face Covers" => "Head & Face Covers", "Motor Oils (Engine Oil, Addictives)" => "Engine Oils for Motorbikes", "Bike Parts (Fenders, Cowls, Deflectors)" => "Motorbike Accessories & Parts"}}
  end

  def self.get_widget_details_from_itemdetails(item_details)
    items = []
    item_details.each do |item_detail|
      item = OpenStruct.new
      item.price = item_detail.price
      item.itemdetail_id = item_detail.item_details_id
      item.name = item_detail.ItemName
      item.image_name = item_detail.Image
      items << item
    end
    items
  end

  def self.amazon_daily_deal_update()
    item = Item.where(:id => 73683).last

    # today_date = Date.today
    # old_date = Date.yesterday

    ActiveRecord::Base.connection.execute("update itemdetails set status = 2 where last_updated <= '#{Date.yesterday.end_of_day}' and itemid=#{item.id}")

    #egressUrl

    page_url = "http://www.amazon.in/gp/goldbox/ref=nav_topnav_deals"
    doc = Nokogiri::HTML(open(page_url))

    deal_details = FeedUrl.get_value_from_pattern(doc.to_s, "var responseJSON<ref_url>= responseJSON", "<ref_url>")

    #click_url = FeedUrl.get_value_from_pattern(doc.to_s, "egressUrl<ref_url>,", "<ref_url>")
    click_url = FeedUrl.get_value_from_pattern(deal_details.to_s, "egressUrl<ref_url>,", "<ref_url>")
    click_url = CGI.unescape(click_url)
    click_url = click_url.gsub(click_url.first, "").gsub(" : ", "")

    #image_url = FeedUrl.get_value_from_pattern(doc.to_s, "primaryImage<ref_url>,", "<ref_url>")
    image_url = FeedUrl.get_value_from_pattern(deal_details.to_s, "primaryImage<ref_url>,", "<ref_url>")
    image_url = CGI.unescape(image_url)
    image_url = image_url.gsub(image_url.first, "").gsub(" : ", "")

    title = FeedUrl.get_value_from_pattern(deal_details.to_s, "title<ref_url>,", "<ref_url>")
    title = CGI.unescape(title)
    title = title.gsub(title.first, "").gsub(" : ", "").squish

    price = FeedUrl.get_value_from_pattern(deal_details.to_s, "minBAmount<ref_url>,", "<ref_url>")
    price = CGI.unescape(price)
    price = price.gsub(price.first, "").gsub(" : ", "").squish

    current_price = FeedUrl.get_value_from_pattern(deal_details.to_s, "minCurrentPrice<ref_url>,", "<ref_url>")
    current_price = CGI.unescape(current_price)
    current_price = current_price.gsub(current_price.first, "").gsub(" : ", "").squish

    saved_percentage = FeedUrl.get_value_from_pattern(deal_details.to_s, "minPercentOff<ref_url>,", "<ref_url>")
    saved_percentage = CGI.unescape(saved_percentage)
    saved_percentage = saved_percentage.gsub(saved_percentage.first, "").gsub(" : ", "").squish


    itemdetail = Itemdetail.where(:itemid => item.id, :url => url).last

    if !itemdetail.blank?
      item_detail.update_attributes!(:ItemName => title, :price => current_price, :savepercentage => saved_percentage, :mrpprice => price, :status => 1)
    else
      item_detail = Itemdetail.new(:itemid => item.id, :ItemName => title, :url => click_url, :price => current_price, :savepercentage => saved_percentage, :mrpprice => price, :status => 1, :iscashondeliveryavailable => false, :isemiavailable => false, :IsError => false, :additional_details => "", :site => "9882", :last_verified_date => Time.now)
      item_detail.save!

      if item_detail.image.blank? || Rails.env != "development"
        filename = image_url.to_s.split("/").last
        filename = filename == "noimage.jpg" ? nil : filename

        filename = filename.gsub("%", "_")

        unless filename.blank?
          name = filename.to_s.split(".")
          name = name[0...name.size-1]
          name = name.join(".") + ".jpeg"
          filename = name
        end

        if !item_detail.blank? && !image_url.blank? && !filename.blank?
          p "image----------------------------"
          @image = item_detail.build_image
          # tempfile = open(image_url)
          # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile})
          # avatar.original_filename = filename

          safe_thumbnail_url = URI.encode(URI.decode(image_url))
          extname = File.extname(safe_thumbnail_url).delete("%")

          basename = File.basename(safe_thumbnail_url, extname).delete("%")

          file = Tempfile.new([basename, extname])
          file.binmode
          open(URI.parse(safe_thumbnail_url), :allow_redirections => :all) do |data|
            file.write data.read
          end
          file.rewind

          avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file, :type => 'image/jpeg'})
          avatar.original_filename = filename

          @image.avatar = avatar
          if @image.save
            item_detail.update_attributes(:Image => filename)
          end
        end
      end
    end
  end

  def self.convert_to_itemdetails(item_details)
    itemdetails = []

    item_details.each do |each_item_detail|
      new_item_detail =  OpenStruct.new(each_item_detail.attributes)
      new_item_detail.site = 9882
      new_item_detail.deal_item = true
      new_item_detail.ItemName = new_item_detail.deal_title
      new_item_detail.price = new_item_detail.deal_price.to_f
      itemdetails << new_item_detail
    end
    itemdetails
  end

  def self.process_and_update_top_itemdetail_for_paytm()
    item_details = Itemdetail.where(:site => 76201).order("shippingunit desc").first(50)

    item_details.each do |item_detail|
      begin
        url = item_detail.url

        json_url = "https://catalog.paytm.com/v1/p/" + url.to_s.split("/").last
        response = RestClient.get(json_url) rescue nil

        response_hash = JSON.parse(response) rescue {}

        if response_hash.blank?
          item_detail.update_attributes(:status => 2)
          next
        end

        product_id = response_hash["product_id"] rescue ""
        status = response_hash["instock"] == true ? 1 : 2
        offer_url = response_hash["offer_url"] rescue ""
        offer_url = "https://paytm.com/papi" + offer_url

        response_offer = RestClient.get(offer_url)
        response_offer_hash = JSON.parse(response_offer) rescue {}

        offer_text = response_offer_hash["codes"][0]["offerText"] rescue ""
        offer_text = offer_text.gsub(/\(Max.*/, "").to_s.strip rescue ""
        effective_price =  response_offer_hash["codes"][0]["effective_price"] rescue ""

        mrpprice = response_hash["actual_price"] rescue ""
        offer_price = response_hash["offer_price"] rescue ""
        cashback = response_offer_hash["codes"][0]["savings"] rescue ""

        order_url = "https://paytm.com/papi/rr/products/#{item_detail.additional_details}/statistics?channel=web&version=2"
        response_order = RestClient.get(order_url) rescue nil
        response_order_hash = JSON.parse(response_order) rescue {}
        order_count = response_order_hash["statistics"]["all"]["order_count"] rescue 0

        # item_detail.update_attributes!(:price => offer_price, :status => status, :last_verified_date => Time.now)
        item_detail.update_attributes!(:mrpprice => mrpprice, :price => offer_price, :status => status, :last_verified_date => Time.now, :offer => offer_text, :cashback => cashback, :description => effective_price, :shippingunit => order_count)
      rescue Exception => e
        p "problem while updating item detail"
      end
    end
  end

  def base_item_image_url(imagetype = :medium)
    item_type = self.type.to_s.downcase rescue self.item.type.to_s.downcase
    if(imagetype == :medium)
      configatron.root_image_url + item_type + '/medium/default_' + item_type + ".jpeg"
    elsif (imagetype == :org)
      configatron.root_image_url + item_type + '/org/default_' + item_type + ".jpeg"
    else
      configatron.root_image_url + item_type + '/small/default_' + item_type + ".jpeg"
    end
  end

  def self.convert_laksh_or_crore_to_num(price)
    price = price.to_s.gsub(",", "")

    if price.include?("Lac")
      price = price.gsub(" Lac", "")
      price = (price.to_f * 100000).round
    elsif price.include?("Cr")
      price = price.gsub(" Cr", "")
      price = (price.to_f * 10000000).round
    end
    price
  end

  private

  def update_last_verified_date
    if self.skip_after_save != true
      self.skip_after_save = true
      self.update_attributes!(:last_updated => Time.now)
    end
  end

end
