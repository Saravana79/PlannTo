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

          # res = Amazon::Ecs.item_lookup("B00B70KYOO", {:response_group => 'Offers', :country => 'in'})
          res = Amazon::Ecs.item_lookup(asin, {:response_group => 'Offers', :country => 'in'})
          p res.is_valid_request?
          if res.is_valid_request?
            item = res.first_item
            unless item.blank?
              offer_listing = item.get_element("Offers/Offer/OfferListing")
              if !offer_listing.blank?
                begin
                  current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                rescue Exception => e
                  current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                end
                saved_price = offer_listing.get_element("AmountSaved").get("FormattedPrice").gsub("INR ", "").gsub(",", "") rescue 0
                saved_percentage = offer_listing.get("PercentageSaved") rescue 0
                availability_str = offer_listing.get("Availability")

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


  def self.update_from_vendors(time=Time.now)
    url = "http://www.mysmartprice.com/store_data/msp_master.xml"
    top_product_ids = [3888,4339,3595,4060,4090,3889,4416,4790,4376,4848,4342,4352,4734,3325,4127,3936,4207,4208,4985,4415,4649,2678,4091,3114,3437,4939,3633,4361,4233,4239,4513,3608,4081,4483,4490,4728,4959,5004,3714,3216,3447,3626,4509,4520,3293,3536,4021,4630,2892,4428,4450,4597,5052,3028,3939,3996,4039,4093,4108,4378,4726,4747,2377,3581,4867,2635,2899,2902,3439,3605,3728,4136,4327,4571,4624,1128,2956,3734,4292,4804,2439,2914,3705,4018,4056,4269,4518,4644,4716,4774,4788,4928,5030,1779,3069,3700,3938,3952,4055,4135,4534,4588,3022,3048,3076,3104,3508,3673,3736,3899,3941,4022,4040,4062,4067,4238,4245,4271,4382,4393,4408,4417,3083,3324,3435,3436,3543,3578,3824,3904,4070,4084,4092,4123,4216,4254,4340,4421,4422,4432,4467,4561,4589,4638,4653,4662,4725,4784,4923,4952,1364,2397,2433,2958,3068,3327,3463,3551,3768,3770,3825,3835,3887,4014,4133,4168,4185,4341,4418,4554,4563,4682,4745,4805,4811,4845,4853,4860,4882,4891,5024,5121,2083,2238,2256,2385,2430,2432,2615,2724,2815,2825,2858,2860,2907,2927,2999,3049,3050,3088,3113,3128,3181,3206,3208,3210,3246,3292,3320,3330,3337,3371,3379,3383,3396,3400,3401,3454,3607,3667,3672,3694,3706,3716,3723,3753,3767,3851,3895,3900,3905,3929,3942,3977,3994,4004,4006,4027,4073,4077,4088,4098,4121,4148,4160,4177,4217,4224,4231,4234,4241,4252,4280,4283,4294,4311,4385,4388,4391,4429,4436,4461,4463,4470,4473,4484,4497,4498,4504,4516,4522,4532,4533,4575,4591,4657,4722,4736,4767,4786,4789,4812,4831,4832,4847,4854,4890,4909,4915,4925,4949,4979,5033,5115,5146]
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
        end

        if !@item_detail.new_record?
          have_to_create_image = @item_detail.Image.blank? ? true : false
          status = [6,13].include?(itemtype_id) && !top_product_ids.include?(id.to_i) ? 6 : 1
          @item_detail.update_attributes!(:price => price, :status => status, :last_verified_date => Time.now, :iscashondeliveryavailable => false, :isemiavailable => false, :IsError => false, :additional_details => id)
        else
          source_item = Sourceitem.find_or_initialize_by_url(url)
          if source_item.new_record?
            source_item.update_attributes(:name => title, :status => 1, :urlsource => "Mysmartprice", :itemtype_id => itemtype_id, :created_by => "System", :verified => false)
          elsif source_item.verified && !source_item.matchitemid.blank?
            status = [6,13].include?(itemtype_id) && !top_product_ids.include?(id.to_i) ? 6 : 1
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
          open(URI.parse(safe_thumbnail_url)) do |data|
            file.write data.read
          end
          file.rewind

          avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file})
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
      process_flipkart_items(each_hash["url"], itemtype_id) unless itemtype_id.blank?
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
          item_count += 1
          total_item_count += 1
          id = item.at_xpath("productBaseInfo//productIdentifier//productId").content rescue nil
          id = id.to_s.downcase rescue nil
          item_info = item.at_xpath("productBaseInfo//productAttributes")
          title = item_info.at_xpath("title").content rescue ""
          url = item_info.at_xpath("productUrl").content rescue ""
          url = url.gsub(/&affid.*/, "")  #remove affiliate id
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
          end
          if !@item_detail.new_record?
            have_to_create_image = @item_detail.Image.blank? ? true : false
            @item_detail.update_attributes!(:price => price, :status => status, :last_verified_date => Time.now, :iscashondeliveryavailable => cod, :isemiavailable => emi, :IsError => false, :additional_details => id)
          else
            s_url = url.split("flipkart.com").last
            source_item = Sourceitem.find_or_initialize_by_url_and_urlsource(s_url, "Flipkart")
            if source_item.new_record?
              source_item.update_attributes(:name => title, :status => 1, :itemtype_id => itemtype_id, :created_by => "System", :verified => false)
            elsif source_item.verified && !source_item.matchitemid.blank?
              @item_detail.update_attributes!(:ItemName => title, :itemid => source_item.matchitemid, :url => url, :price => price, :status => status, :last_verified_date => Time.now, :site => 9861, :iscashondeliveryavailable =>cod, :isemiavailable => emi, :IsError => false, :additional_details => id)
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
            open(URI.parse(safe_thumbnail_url)) do |data|
              file.write data.read
            end
            file.rewind

            avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file})
            avatar.original_filename = filename

            @image.avatar = avatar
            if @image.save
              @item_detail.update_attributes(:Image => filename)
            end
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
      asin = url[/.*\/dp\/(.*)/m,1]
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

end
