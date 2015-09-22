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

            avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file})
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

        avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file})
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
  items_sql = "select * from items where (updated_at > '2015-08-30')"

  page = 1
  begin
    items = Item.paginate_by_sql(items_sql, :page => page, :per_page => 1000)

    items.each do |each_item|
      each_item.update_redis_with_item_manual()
    end
    page += 1
    break
  end while !items.empty?
end


desc "update content mapping to redis rtb"
task :update_content_mapping_to_redis_rtb => :environment do
  content_sql = "SELECT `view_article_contents`.* FROM `view_article_contents` WHERE `view_article_contents`.`type` IN ('ArticleContent', 'VideoContent') AND (updated_at > '2015-08-30')"

  page = 1
  begin
    contents = Content.paginate_by_sql(content_sql, :page => page, :per_page => 1000)

    contents.each do |each_content|
      each_content.update_item_contents_relations_cache(each_content)
    end
    page += 1
    break
  end while !contents.empty?
end

desc "tmp job to update item beauty detail"
task :update_item_beauty_detail_from_xml_feed => :environment do
  # data = XmlSimple.xml_in(File.open("/home/sivakumar/skype/335-21092015-085816.xml"))
  data = XmlSimple.xml_in(open("http://feeds.omgpm.com/GetFeed/?aid=524511&feedid=335&Format=xml"))

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
          doc = Nokogiri::HTML(open(uri, "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0"))

          color_label = doc.at_css("#selected_color_label").content.to_s.downcase rescue ""
        rescue Exception => e
          color_label = ""
        end

        item_beauty_detail.update_attributes!(:name => name, :price => offer_price, :status => status, :last_verified_date => Time.now, :site => 76326, :additional_details => product_id, :description => description, :is_error => false, :mrp_price => mrp_price, :gender => gender, :color => color_label)
        image = item_beauty_detail.image
      else
        item_beauty_detail.update_attributes!(:price => offer_price, :status => status, :last_verified_date => Time.now)
        image = item_beauty_detail.image
      end

      begin
        if image.blank? && !image_url.blank?
          image = item_beauty_detail.build_image
          tempfile = open(image_url)
          avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile})
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


