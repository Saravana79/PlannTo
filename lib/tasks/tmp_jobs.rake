desc "temporary rake task"
task :buying_list_from_user_access => :environment do
  user_access_details = UserAccessDetail.all
  count = user_access_details.count

  loop_count = 0

  user_access_details.each do |user_access_detail|
    loop_count+=1
    article_content = ArticleContent.where(:url => user_access_detail.ref_url).last

    unless article_content.blank?
      user_id = user_access_detail.plannto_user_id
      type = article_content.sub_type
      item_ids = article_content.item_ids.join(",") rescue ""
      itemtype_id = article_content.itemtype_id
      begin
        UserAccessDetail.update_buying_list(user_id, user_access_detail.ref_url, type, item_ids, nil, nil, itemtype_id)
      rescue Exception => e
        p "There was a problem => #{e}"
      end
    end
    p "Remaining #{count-loop_count}"
  end
end

desc "temporary rake task to update item detail others"
task :update_item_detail_others, [:url] => :environment do |_, args|
  args.with_defaults(:url => "http://planntonew.s3.amazonaws.com/test_folder/junglee_cars.csv")
  count = 0
  url = args[:url].to_s
  csv_details = CSV.read(open(url), { :col_sep => "\t" })
  csv_details.each_with_index do |csv_detail, index|
    count += 1
    next if index == 0

    each_url = csv_detail[0]
    each_url = each_url.to_s
    each_url = "http://" + each_url if !each_url.include?("http")

    begin
      ItemDetailOther.update_item_detail_other_for_junglee(each_url)
    rescue Exception => e
      p e
    end
    p "Processing #{count}"
  end
end

desc "temporary rake task to update item detail others temp"
task :update_item_detail_others_temp, [:url] => :environment do |_, args|
  count = 0
  url = args[:url].to_s
  csv_details = CSV.read(open(url), { :col_sep => "\t" })

  count = 0
  mapping_import = []
  csv_details.each_with_index do |csv_detail, index|
    url = csv_detail[1]
    price = csv_detail[6]

    url = url.to_s
    url = "http://" + url if !url.include?("http")
    item_detail_other = ItemDetailOther.where(:url => url).last

    next if index == 0
    count += 1

    if !item_detail_other.blank?
      if price.blank?
        item_detail_other.update_attributes(:status => 1, :last_updated_at => Time.now)
      else
        item_detail_other.update_attributes(:status => 1, :last_updated_at => Time.now, :price => price)
      end
    else
      begin
        itemtype_id = nil
        url = url.to_s
        url = "http://" + url if !url.include?("http")

        doc = Nokogiri::XML(open(url))
        node = doc.elements.first
        search_type = [Car,Bike]
        status = 1

        itemtype_str = node.at_css("#mainTop-1").content.to_s.squish.downcase rescue ""

        if itemtype_str.include?("motorcycles")
          search_type = [Bike]
        end

        table = node.at_css(".centerColumn #center-5 table")
        title = node.at_css(".productTitle").content.squish rescue ""
        price = node.at_css(".whole-price").content.squish rescue ""
        price = price.gsub(",","").gsub(".", "")
        status = 2 if price.blank?
        location = node.at_css("#location .importantDetail").content.squish rescue ""
        image_url = node.at_css("#mainImageContainer img").attributes["src"].content rescue ""
        image_url = image_url.to_s.gsub("._AA300_", "")
        search_text = ""
        ad_detail1 = ""
        ad_detail2 = ""
        ad_detail3 = ""
        ad_detail4 = ""
        table.elements.each do |each_ele|
          type = each_ele.elements.first.content.to_s.squish rescue ""
          value = each_ele.elements.last.content.to_s.squish rescue ""
          if type == "Brand"
            search_text = search_text + " " + value
          elsif type == "Model"
            search_text = search_text + " " + value
          elsif type == "Version"
            search_text = search_text + " " + value
          elsif type == "Year of Registration"
            ad_detail4 = value
          elsif type == "KMs Driven"
            ad_detail2 = value
          elsif type == "Fuel Type"
            ad_detail1 = value
          elsif type == "Transmission Type"
            ad_detail3 = value
          end
        end

        if item_detail_other.blank?
          item_detail_other = ItemDetailOther.new(:title => title, :price => price, :url => url, :status => status, :ad_detail1 => ad_detail1, :ad_detail2 => ad_detail2,
                                                  :ad_detail3 => ad_detail3, :ad_detail4 => ad_detail4, :added_date => Date.today, :vendor_id => 73017, :last_updated_at => Time.now)
          item_detail_other.save!

          places = Sunspot.search([City,Place]) do
            keywords location do
              minimum_match 1
            end
            order_by :score,:desc
            order_by :orderbyid , :asc
            paginate(:page => 1, :per_page => 5)
          end

          city = places.results.first rescue nil

          score = places.hits.first.score.to_f rescue 0

          city = nil if score < 0.3

          status = ItemDetailOther::INVALID_STATUS if city.blank?

          if !city.blank?
            mapping_import << ItemDetailOtherMapping.new(:item_detail_other_id => item_detail_other.id, :item_id => city.id)

            item_detail_other.update_attributes(:location_id => city.id)
          end

          search_type = Product.search_type(nil) if search_type.blank?

          cars = Sunspot.search(search_type) do
            keywords search_text do
              minimum_match 1
            end
            order_by :score,:desc
            order_by :orderbyid , :asc
            paginate(:page => 1, :per_page => 5)
          end

          car = cars.results.first rescue nil
          if !car.blank?
            car_group = car.group
            itemtype_id = car.itemtype_id
          end
          car = car_group if !car_group.blank?

          score = cars.hits.first.score.to_f rescue 0

          car = nil if score < 0.3

          status = ItemDetailOther::INVALID_STATUS if car.blank?

          if !car.blank?
            mapping_import << ItemDetailOtherMapping.new(:item_detail_other_id => item_detail_other.id, :item_id => car.id)
          end

          if status != 1
            item_detail_other.update_attributes!(:status => status, :last_updated_at => Time.now)
          end

          if !itemtype_id.blank?
            item_detail_other.update_attributes!(:itemtype_id => itemtype_id, :last_updated_at => Time.now)
          end

          p "Processing count => #{count}"
          if count > 1000
            ItemDetailOtherMapping.import(mapping_import)
            mapping_import = []
            count = 0
          end

          image_url = image_url.to_s.gsub("._AA300_", "")
          filename = image_url.to_s.split("/").last
          filename = filename == "noimage.jpg" ? nil : filename

          filename = filename.gsub("%", "_")

          unless filename.blank?
            name = filename.to_s.split(".")
            name = name[0...name.size-1]
            name = name.join(".") + ".jpeg"
            filename = name
          end

          if !item_detail_other.blank? && !image_url.blank? && !filename.blank?
            p "image----------------------------"
            @image = item_detail_other.build_image
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

            avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file, :type => 'image/jpeg'})
            avatar.original_filename = filename

            @image.avatar = avatar
            if @image.save
              item_detail_other.update_attributes(:image_name => filename, :last_updated_at => Time.now)
            end
          end

        else
          item_detail_other.update_attributes(:price => price, :last_updated_at => Time.now)
        end
      rescue Exception => e
        p e.message
      end
    end
  end

  #update all to set status 2
  ActiveRecord::Base.connection.execute("update item_detail_others set status = 2 where vendor_id = 73017 and last_updated_at < '#{1.day.ago}' or price is null or price = 0")
end



desc "image upload job"
task :image_upload_for_item_detail_other => :environment do
  ids = ItemDetailOther.where(:image_name => nil)
  ids.each do |item_detail_other|
    begin
      url = item_detail_other.url
      doc = Nokogiri::XML(open(url))
      node = doc.elements.first
      image_url = node.at_css("#mainImageContainer img").attributes["src"].content rescue ""
      image_url = image_url.to_s.gsub("._AA300_", "")
      filename = image_url.to_s.split("/").last
      filename = filename == "noimage.jpg" ? nil : filename

      filename = filename.gsub("%", "_")

      unless filename.blank?
        name = filename.to_s.split(".")
        name = name[0...name.size-1]
        name = name.join(".") + ".jpeg"
        filename = name
      end

      if !item_detail_other.blank? && !image_url.blank? && !filename.blank?
        p "image----------------------------"
        @image = item_detail_other.build_image
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

        avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file, :type => 'image/jpeg'})
        avatar.original_filename = filename

        @image.avatar = avatar
        if @image.save
          item_detail_other.update_attributes(:image_name => filename)
        end
      end
    rescue Exception => e
      p "error "
    end
  end
end


desc "image upload job"
task :mapping_fixes => :environment do
  query = "select * from item_detail_others where itemtype_id is null"

  page = 1
  begin
    item_details = ItemDetailOther.paginate_by_sql(query, :page => page, :per_page => 1000)

    item_details.each do |item_detail_other|
      begin
        itemtype_id = nil
        status = 1
        url = item_detail_other.url.to_s
        url = "http://" + url if !url.include?("http")

        doc = Nokogiri::XML(open(url))
        node = doc.elements.first

        table = node.at_css(".centerColumn #center-5 table") rescue nil
        search_type = [Car,Bike]

        itemtype_str = node.at_css("#mainTop-1").content.to_s.squish.downcase rescue ""

        if itemtype_str.include?("motorcycles")
          search_type = [Bike]
        end

        search_text = ""
        ad_detail1 = ""
        ad_detail2 = ""
        ad_detail3 = ""
        ad_detail4 = ""
        table.elements.each do |each_ele|
          type = each_ele.elements.first.content.to_s.squish rescue ""
          value = each_ele.elements.last.content.to_s.squish rescue ""
          if type == "Brand"
            search_text = search_text + " " + value
          elsif type == "Model"
            search_text = search_text + " " + value
          elsif type == "Version"
            search_text = search_text + " " + value
          elsif type == "Year of Registration"
            ad_detail4 = value
          elsif type == "KMs Driven"
            ad_detail2 = value
          elsif type == "Fuel Type"
            ad_detail1 = value
          elsif type == "Transmission Type"
            ad_detail3 = value
          end
        end

        cars = Sunspot.search(search_type) do
          keywords search_text do
            minimum_match 1
          end
          order_by :score,:desc
          order_by :orderbyid , :asc
          paginate(:page => 1, :per_page => 5)
        end

        car = cars.results.first rescue nil
        check_car = car
        if !car.blank?
          car_group = car.group
          itemtype_id = car.itemtype_id
        end
        car = car_group if !car_group.blank?

        score = cars.hits.first.score.to_f rescue 0

        car = nil if score < 0.3

        status = ItemDetailOther::INVALID_STATUS if car.blank?

        mappings = item_detail_other.item_detail_other_mappings

        mappings.each do |m_item|
          mapped_item = Item.find m_item.item_id
          if mapped_item.is_a?(Car) || mapped_item.is_a?(Bike)
            if car.blank?
              m_item.destroy
            elsif check_car == mapped_item || car == mapped_item
              itemtype_id = itemtype_id
            else
              item_map = ItemDetailOtherMapping.where(:item_detail_other_id => item_detail_other.id, :item_id => mapped_item.id)

              if item_map.blank?
                ItemDetailOtherMapping.create(:item_detail_other_id => item_detail_other.id, :item_id => mapped_item.id)
              end
            end
          end
        end

        item_detail_other.update_attributes(:status => status, :itemtype_id => itemtype_id)

      rescue Exception => e
        p "error"
        status = ItemDetailOther::INVALID_STATUS
        item_detail_other.update_attributes(:status => status)
      end
    end

    page += 1
  end while !item_details.empty?
end

desc "temporary rake task"
task :plannto_user_detail_process => :environment do
  plannto_user_details = PlanntoUserDetail.where(:lad.gte => "#{1.week.ago}", :agg_info.exists => false)

  total_count = plannto_user_details.count

  plannto_user_details.each do |plannto_user_detail|
    total_count-=1
    p "Remaining count => #{total_count}"
    begin
      agg_info_arr = []
      item_types = plannto_user_detail.m_item_types
      item_types.each do |item_type|
        r = item_type.r == true ? "r" : ""
        itemtype_id = item_type.itemtype_id
        if !r.blank?
          agg_info_arr << "#{itemtype_id}:r:1"
        else
          agg_info_arr << "#{itemtype_id}:1"
        end
      end
      plannto_user_detail.agg_info = agg_info_arr.join(",")
      plannto_user_detail.save!
    rescue Exception => e
      p "Error => #{plannto_user_detail.plannto_user_id}"
    end
  end
end

desc "temporary rake task"
task :remove_old_plannto_user_details => :environment do
  # plannto_user_details = PlanntoUserDetail.delete_all(:lad.lte => "#{1.month.ago}")
  plannto_user_details = PlanntoUserDetail.delete_all(conditions: {"lad" => {"$lte" => 1.month.ago}})
end

desc "paytm product update"
task :update_source_item_with_paytm => :environment do

  url = "/home/sivakumar/Downloads/feed.xml"
  each_node_list = Nokogiri::XML::Reader(File.open(url)).first

  each_node_list.first
  product_types = []
  source_items = []
  each_node_list.each_with_index do |each_node, index|
    begin
      p index += 1
      logger.info index += 1
      if each_node.local_name == "item"
        outer_item_xml = each_node.outer_xml

        xml_hash = XmlSimple.xml_in(outer_item_xml)
        product_type = xml_hash["product_type"][0] rescue ""
        product_type = product_type.split(">").last.strip rescue ""
        if ["Mobiles", "Tablets", "Laptops", "DSLR", "Point & Shoot"].include?(product_type)
          p "-------------------------------------------------------------------------------"
          logger.info "-------------------------------------------------------------------------------"
          p product_type
          logger.info product_type
          product_types << product_type
          p "success"
          logger.info "success"
          # process_count += 1
          url = xml_hash["link"][0] rescue ""
          title = xml_hash["title"][0] rescue ""
          itemtype_id = case product_type
                          when "Mobiles"
                            6
                          when "Tablets"
                            13
                          when "Laptops"
                            23
                          when "DSLR", "Point & Shoot"
                            12
                        end

          source_item = Sourceitem.new(:url => url, :name => title, :status => 1, :urlsource => "Paytm", :itemtype_id => itemtype_id, :created_by => "System", :verified => false)

          source_items << source_item

          if source_items.count > 2
            Sourceitem.import(source_items)
            source_items = []
          end
        end
      end
    rescue Exception => e
      p e
      p "3333333333333333"
      p product_types
    end
  end
end

desc "paytm - sourceitem update to item details"
task :update_source_item_to_item_detail => :environment do
  Sourceitem.process_source_item_update_paytm()
end

desc "update items mapping to redis rtb"
task :update_item_mapping_to_redis_rtb => :environment do
  items_sql = "select * from items where (updated_at > '2011-01-1')"

  page = 1
  count = 0
  begin
    items = Item.paginate_by_sql(items_sql, :page => page, :per_page => 1000)

    items.each do |each_item|
      begin
        count += 1
        each_item.update_redis_with_item_manual()
        p "---------#{count}-----------"
      rescue Exception => e
        p "Errors in item mapping"
      end
    end
    page += 1
  end while !items.empty?
end


desc "update content mapping to redis rtb"
task :update_content_mapping_to_redis_rtb => :environment do
  content_sql = "SELECT `view_article_contents`.* FROM `view_article_contents` WHERE `view_article_contents`.`type` IN ('ArticleContent', 'VideoContent') AND (updated_at > '2011-01-1')"

  page = 1
  count = 0
  begin
    contents = Content.paginate_by_sql(content_sql, :page => page, :per_page => 1000)

    contents.each do |each_content|
      count += 1
      begin
        each_content.update_item_contents_relations_cache(each_content)
        p "---------#{count}-----------"
      rescue Exception => e
        p "Error in content update"
      end
    end
    page += 1
  end while !contents.empty?
end

desc "tmp job to update item beauty detail"
task :update_item_beauty_detail_from_xml_feed => :environment do
  # data = XmlSimple.xml_in(File.open("/home/sivakumar/skype/335-21092015-085816.xml"))
  # url = "http://feeds.omgpm.com/GetFeed/?aid=524511&feedid=335&Format=xml"
  url = "http://cdn1.plannto.com/test_folder/335-21092015-085816.xml"
  data = XmlSimple.xml_in(open(url))

  products = data["Product"]

  products.each do |each_product|
    begin
      url = each_product["ProductURL"][0].to_s rescue ""
      url = CGI.unescape(url) rescue ""
      url = FeedUrl.get_value_from_pattern(url, "r=<url>?", "<url>").strip rescue ""
      item_beauty_detail = ItemBeautyDetail.find_or_initialize_by_url(:url => url)
      name = each_product["ProductName"][0].to_s rescue ""
      offer_price = each_product["ProductPrice"][0] rescue ""
      status = each_product["StockAvailability"][0].to_s.downcase.include?("in stock") ? 1 : 2 rescue 2
      image_url = each_product["ProductImageLargeURL"][0].to_s rescue ""
      mrp_price = each_product["WasPrice"][0] rescue ""
      description = each_product["ProductDescription"][0].to_s rescue ""
      product_id = each_product["ProductID"][0].to_s rescue ""
      category = each_product["CategoryName"][0].to_s rescue ""
      gender = each_product["custom1"][0].to_s rescue ""
      gender = FeedUrl.get_value_from_pattern(gender, "Gender -<gender>", "<gender>").to_s.strip.downcase rescue ""

      if item_beauty_detail.new_record?
        begin
          uri = URI.parse(URI.encode(url.to_s.strip))
          # doc = Nokogiri::HTML(open(uri, "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0"))

          response_page = ""
          begin
            Timeout.timeout(30) do
              response_page = open(uri, "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0", :allow_redirections => :all)
            end
          rescue Exception => e
            response_page = ""
          end
          doc = Nokogiri::HTML(response_page)

          color_label = doc.at_css("#selected_color_label").content.to_s.downcase rescue ""
        rescue Exception => e
          color_label = ""
        end

        item_beauty_detail.update_attributes!(:name => name, :price => offer_price, :status => status, :last_verified_date => Time.now, :site => 76326, :additional_details => product_id, :description => description, :is_error => false, :mrp_price => mrp_price, :gender => gender, :color => color_label)
        image = item_beauty_detail.image_name
      else
        item_beauty_detail.update_attributes!(:price => offer_price, :status => status, :last_verified_date => Time.now)
        image = item_beauty_detail.image_name
      end

      begin
        if image.blank? && !image_url.blank?
          image = item_beauty_detail.build_image
          tempfile = open(image_url)
          avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile, :type => 'image/jpeg'})
          # filename = image_url.split("/").last
          filename = "#{item_beauty_detail.id}.jpeg"
          avatar.original_filename = filename
          image.avatar = avatar
          image.save
        end
      rescue Exception => e
        p e.backtrace
        p "There was a problem in image update"
        p "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        p url
      end
    rescue Exception => e
      p "Error problem on product update"
      p each_product["ProductURL"][0].to_s rescue ""
    end
  end
end


desc "update additional details in item details and itemexternalurls"
task :update_additional_details_in_item_details_and_itemexternalurls => :environment do
  query_for_amazon = "select * from itemdetails where site=9882"
  page = 1
  begin
    item_details = Itemdetail.paginate_by_sql(query_for_amazon, :page => page, :per_page => 1000)

    item_details.each do |item_detail|
      begin
        p "amazon"
        p add_id = Itemdetail.get_vendor_product_id(item_detail.url)
        item_detail.update_attributes(:additional_details => add_id) if !add_id.blank?
      rescue Exception => e
        p "Error amazon"
      end
    end

    page += 1
  end while !item_details.empty?

  query_for_flipkart = "select * from itemdetails where site=9861"
  page = 1
  begin
    item_details = Itemdetail.paginate_by_sql(query_for_flipkart, :page => page, :per_page => 1000)

    item_details.each do |item_detail|
      begin
        p "flipkart"
        p add_id = Itemdetail.get_vendor_product_id(item_detail.url)
        item_detail.update_attributes(:additional_details => add_id) if !add_id.blank?
      rescue Exception => e
        p "Error flipkart"
      end
    end
    page += 1
  end while !item_details.empty?

  query_for_snapdeal = "select * from itemdetails where site=9874"
  page = 1
  begin
    item_details = Itemdetail.paginate_by_sql(query_for_snapdeal, :page => page, :per_page => 1000)

    item_details.each do |item_detail|
      begin
        p "Snapdeal"
        p add_id = Itemdetail.get_vendor_product_id(item_detail.url)
        item_detail.update_attributes(:additional_details => add_id) if !add_id.blank?
      rescue Exception => e
        p "Error Snapdeal"
      end
    end
    page += 1
  end while !item_details.empty?

  query_for_item_external_url = "select * from itemexternalurls"
  page = 1
  begin
    item_external_urls = Itemexternalurl.paginate_by_sql(query_for_item_external_url, :page => page, :per_page => 1000)

    item_external_urls.each do |item_external_url|
      begin
        p "item external url"
        p add_id = Itemdetail.get_vendor_product_id(item_external_url.URL.to_s)
        item_external_url.update_attributes(:additional_details => add_id) if !add_id.blank?
      rescue Exception => e
        p "Error item external url"
      end
    end
    page += 1
  end while !item_external_urls.empty?
end


desc "destroy duplicate items in item details and itemexternalurls"
task :destroy_duplicate_items_in_item_details_and_itemexternalurls => :environment do
  grouped = Itemdetail.where(:site => 9861).group_by{|model| [model.additional_details] } rescue []
  grouped.values.each do |duplicates|
    # the last one we want to keep right?
    last_one = duplicates.pop # pop for last one
    # if there are any more left, they are duplicates
    # so delete all of them
    duplicates.each{|double| double.destroy} # duplicates can now be destroyed
  end

  grouped = Itemdetail.where(:site => 9882).group_by{|model| [model.additional_details] } rescue []
  grouped.values.each do |duplicates|
    # the last one we want to keep right?
    last_one = duplicates.pop # pop for last one
    # if there are any more left, they are duplicates
    # so delete all of them
    duplicates.each{|double| double.destroy} # duplicates can now be destroyed
  end

  grouped = Itemdetail.where(:site => 9874).group_by{|model| [model.additional_details] } rescue []
  grouped.values.each do |duplicates|
    # the last one we want to keep right?
    last_one = duplicates.pop # pop for last one
    # if there are any more left, they are duplicates
    # so delete all of them
    duplicates.each{|double| double.destroy} # duplicates can now be destroyed
  end
end

desc "Update mouthshut details to feed url"
task :update_mouthshut_details_to_feed_url => :environment do
  admin_user = User.first
  # sources_list = JSON.parse($redis.get("sources_list_details"))
  # sources_list.default = "Others"

  url = "http://planntonew.s3.amazonaws.com/test_folder/mobile_products_catalog.csv"
  csv_details = CSV.read(open(url))

  csv_details.each_with_index do |csv_detail, index|
    next if index == 0

    url = csv_detail[2]
    check_exist_feed_url = FeedUrl.where(:url => url).first
    if check_exist_feed_url.blank?
      source = ""
      begin
        source = URI.parse(URI.encode(URI.decode(url))).host.gsub("www.", "")
      rescue Exception => e
        source = Addressable::URI.parse(url).host.gsub("www.", "")
      end
      article_content = ArticleContent.find_by_url(url)
      status = 0
      status = 1 unless article_content.blank?

      title, description, images, page_category = Feed.get_feed_url_values(url)

      url_for_save = url
      if url_for_save.include?("youtube.com")
        url_for_save = url_for_save.gsub("watch?v=", "video/")
      end

      # remove characters after come with space + '- or |' symbols
      title = title.to_s.gsub(/\s(-|\|).+/, '')
      title = title.blank? ? "" : title.to_s.strip

      # category = sources_list[source]["categories"]

      SourceCategory.find_by_source(source).categories rescue ""
      category = "Others" if category.blank?

      new_feed_url = FeedUrl.new(feed_id: 41, url: url_for_save, title: title.to_s.strip, category: category,
                                 status: status, source: source, summary: description, :images => images,
                                 :published_at => Time.now, :priorities => 1, :additional_details => page_category)

      begin
        new_feed_url.save!
        feed_url, article_content = ArticleContent.check_and_update_mobile_site_feed_urls_from_feed(new_feed_url, admin_user, nil)
        feed_url.auto_save_feed_urls(false,0,"auto") if feed_url.status == 0
      rescue Exception => e
        p e
      end
    end
  end
end


task :update_feed_url_with_title_desc => :environment do

  query = "select * from feed_urls where created_at > '#{Date.today - 2}' and title =''"

  page = 1
  begin
    feed_urls = FeedUrl.paginate_by_sql(query, :page => page, :per_page => 1000)

    feed_urls.each do |feed_url|
      begin
        valid_categories=["science & technology","Autos & Vehicles","Science & Tech"]
        SourceCategory.find_by_source(feed_url.source).categories rescue ""
        category = "Others" if category.blank?
        url = feed_url.url.to_s
        title, description, images, page_category = Feed.get_feed_url_values(url)

        images = images.to_s.split(",").uniq.join(",")

        if category.to_s.split(",").include?("ApartmentType")
          begin
            page_category = FeedUrl.get_additional_details_for_housing(url)
          rescue Exception => e
            p "error message"
          end
        end

        url_for_save = url
        if url_for_save.include?("youtube.com")
          url_for_save = url_for_save.gsub("watch?v=", "video/")
        end

        if !page_category.blank?
          if !valid_categories.include?(page_category.downcase)
            status = 3
          elsif page_category.downcase == 'science & technology'
            category = "Mobile,Tablet,Camera,Laptop"
          end
        end

        begin
          verticals = feed_url.article_category
          vertical_ids = verticals.to_s.split(",").compact.select {|d| !d.blank? && d.to_s != "nil" && d.to_s != "0"}
          google_content_categories = vertical_ids.blank? ? [] : GoogleContentCategory.where(:category_id => vertical_ids)

          plannto_categories = []
          google_content_categories.each do |google_content_category|
            plannto_category  = google_content_category.plannto_category
            if plannto_category.blank?
              parent = google_content_category.parent
              begin
                break if parent.blank?
                plannto_category  = parent.plannto_category
                parent  = parent.parent
              end while plannto_category.blank? && !parent.blank?
            end
            plannto_categories << plannto_category
          end

          new_categories = plannto_categories.compact.uniq

          if new_categories.count <= 4
            new_category = new_categories.join(",")
          else
            new_category = ""
          end
        rescue Exception => e
          new_category = ""
        end

        category = new_category if !new_category.blank?

        # remove characters after come with space + '- or |' symbols
        # title = title.to_s.gsub(/\s(-|\|).+/, '')
        title = title.blank? ? "" : title.to_s.strip

        new_feed_url = feed_url.update_attributes(title: title.to_s.strip, category: category,
                                                  status: status, summary: description, :images => images,
                                                  :additional_details => page_category)
      rescue Exception => e
        p "problem in update"
      end
    end

    page += 1
  end while !feed_urls.empty?

end