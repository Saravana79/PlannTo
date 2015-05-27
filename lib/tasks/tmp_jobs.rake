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
  args.with_defaults(:url => "http://planntonew.s3.amazonaws.com/test_folder/junglee_cars.csv")
  count = 0
  url = args[:url].to_s
  csv_details = CSV.read(open(url), { :col_sep => "\t" })

  count = 0
  mapping_import = []
  csv_details.each_with_index do |csv_detail, index|
    url = csv_detail[0]
    url = url.to_s
    url = "http://" + url if !url.include?("http")
    item_detail_other = ItemDetailOther.where(:url => url).last

    next if index == 0 || !item_detail_other.blank?
    count += 1

    begin
      url = url.to_s
      url = "http://" + url if !url.include?("http")

      doc = Nokogiri::XML(open(url))
      node = doc.elements.first

      table = node.at_css(".centerColumn #center-5 table")
      title = node.at_css(".productTitle").content.squish rescue ""
      price = node.at_css(".whole-price").content.squish rescue ""
      price = price.gsub(",","").gsub(".", "")
      location = node.at_css("#location .importantDetail").content.squish rescue ""
      image_url = node.at_css("#mainImageContainer img").attributes["src"].content rescue ""
      status = 1
      search_text = ""
      ad_detail1 = ""
      ad_detail2 = ""
      ad_detail3 = ""
      ad_detail4 = ""
      table.elements.each do |each_ele|
        type = each_ele.elements.first.content.to_s.squish rescue ""
        value = each_ele.elements.last.content.to_s.squish rescue ""
        if type == "Brand"
          search_text = value
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
                                                :ad_detail3 => ad_detail3, :ad_detail4 => ad_detail4, :added_date => Date.today, :last_modified_date => Date.today)
        item_detail_other.save!

        @items = Sunspot.search([City]) do
          keywords location do
            minimum_match 1
          end
          order_by :score,:desc
          order_by :orderbyid , :asc
          paginate(:page => 1, :per_page => 5)
        end

        item = @items.results.first rescue nil

        if !item.blank?
          mapping_import << ItemDetailOtherMapping.new(:item_detail_other_id => item_detail_other.id, :item_id => item.id)
        end

        cars = Sunspot.search([Car]) do
          keywords search_text do
            minimum_match 1
          end
          order_by :score,:desc
          order_by :orderbyid , :asc
          paginate(:page => 1, :per_page => 5)
        end

        car = cars.results.first rescue nil

        if !car.blank?
          mapping_import << ItemDetailOtherMapping.new(:item_detail_other_id => item_detail_other.id, :item_id => car.id)
        end

        p "Processing count => #{count}"
        if count > 1000
          ItemDetailOtherMapping.import(mapping_import)
          mapping_import = []
          count = 0
        end

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

      else
        item_detail_other.update_attributes(:price => price, :last_modified_date => Date.today)
      end
    rescue Exception => e
      p e.backtrace
    end
  end
end



