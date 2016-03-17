class Sourceitem < ActiveRecord::Base
  # validates_uniqueness_of :url
  belongs_to :itemtype

  def self.update_suggestions
    @source_items = Sourceitem.where(:verified => false, :suggestion_id => nil)
    count = 0
    @source_items.each do |source_item|
      begin
        param = {:term => source_item.name}
        type = source_item.itemtype.itemtype
        itemtypes = type.blank? ? nil : [*type]

        results, selected_list, list_scores, auto_save = Product.get_search_items_by_relavance(param, itemtypes)
        result = results.first
        unless result.blank?
          count = count + 1
          source_item.update_attributes!(:suggestion_id => result[:id], :suggestion_name => result[:value])
        end
      rescue Exception => e
        puts e.backtrace
      end
    end
    count
  end

  def self.update_source_item_for_auto_portals()
    require 'xmlsimple'
    url = "http://autoportal.com/vizury_feed.xml"
    xml_data = Net::HTTP.get_response(URI.parse(url)).body
    data = XmlSimple.xml_in(xml_data)
    items = data["Row"]

    items.each do |item|
      pid = item["model_id"][0]
      title = item["pname"][0]
      url = item["landing_page"][0]
      price = item["Sale_price"][0]
      image_url = item["image"][0]
      mileage = item["mileage"][0]
      fueltype = item["fueltype"][0]
      emi_value = item["monthly_emi"][0]
      emi_available = !emi_value.blank?

      if !url.include?(".htm")
        next
      end

      source_item = Sourceitem.find_or_initialize_by_url(url)
      if source_item.new_record?
        source_item.update_attributes(:name => title, :status => 1, :urlsource => "Autoportal", :itemtype_id => 1, :created_by => "System", :verified => false, :additional_details => pid)
      elsif source_item.verified && !source_item.matchitemid.blank?
        item_detail = Itemdetail.find_or_initialize_by_url(url)
        if item_detail.new_record?
          item_detail.update_attributes!(:ItemName => title, :itemid => source_item.matchitemid, :url => url, :price => price, :status => 1, :last_verified_date => Time.now, :site => 75798, :iscashondeliveryavailable => false, :isemiavailable => emi_available, :additional_details => pid, :cashback => emi_value, :description => "#{mileage}|#{fueltype}", :IsError => false)
          image = item_detail.Image
        else
          item_detail.update_attributes!(:price => price, :status => 1, :last_verified_date => Time.now)
          image = item_detail.Image
        end
        begin
          if image.blank? && !image_url.blank?
            image = item_detail.build_image
            tempfile = open(image_url)
            avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile, :type => 'image/jpeg'})
            filename = image_url.split("/").last
            avatar.original_filename = filename
            image.avatar = avatar
            image.save
          end
        rescue Exception => e
          p "There was a problem in image update"
        end
      end
    end
  end

  def self.process_source_item_update_paytm()
    source_items = Sourceitem.where("verified=true and matchitemid is not null and url like '%paytm.com%'")

    source_items.each do |source_item|
      begin
        if source_item.verified && !source_item.matchitemid.blank?
          json_url = "https://catalog.paytm.com/v1/p/" + source_item.url.to_s.split("/").last
          response = RestClient.get(json_url) rescue nil

          response_hash = JSON.parse(response) rescue {}

          if response_hash.blank?
            item_detail = Itemdetail.find_or_initialize_by_url(source_item.url)
            item_detail.update_attributes(:status => 2)
            next
          end

          product_id = response_hash["product_id"] rescue ""
          image_url = response_hash["image_url"] rescue ""
          status = response_hash["instock"] == true ? 1 : 2
          offer = response_hash["promo_text"] rescue ""
          offer_url = response_hash["offer_url"] rescue ""
          offer_url = "https://paytm.com/papi" + offer_url

          response_offer = RestClient.get(offer_url)
          response_offer_hash = JSON.parse(response_offer) rescue {}

          offer_text = response_offer_hash["codes"][0]["offerText"] rescue ""
          offer_text = offer_text.gsub(/\(Max.*/, "").to_s.strip rescue ""
          effective_price =  response_offer_hash["codes"][0]["effective_price"] rescue ""

          title = response_hash["name"] rescue ""
          mrpprice = response_hash["actual_price"] rescue ""
          offer_price = response_hash["offer_price"] rescue ""
          description = response_hash["meta_description"] rescue ""
          cashback = response_offer_hash["codes"][0]["savings"] rescue ""
          isemiavailable = offer.to_s.downcase.include?("emi available") ? true : false
          iscashondeliveryavailable = offer.to_s.downcase.include?("cod option will be available") ? true : false

          item_detail = Itemdetail.find_or_initialize_by_url(source_item.url)
          if item_detail.new_record?
            item_detail.update_attributes!(:ItemName => title, :itemid => source_item.matchitemid, :url => source_item.url, :price => offer_price, :status => status, :last_verified_date => Time.now, :site => 76201, :iscashondeliveryavailable => iscashondeliveryavailable, :isemiavailable => isemiavailable, :additional_details => product_id, :cashback => cashback, :description => effective_price, :IsError => false, :mrpprice => mrpprice, :offer => offer_text)
            image = item_detail.Image
          else
            # order_url = order_url.gsub("<product_id>", product_id.to_s)
            order_url = "https://paytm.com/papi/rr/products/#{item_detail.additional_details}/statistics?channel=web&version=2"
            response_order = RestClient.get(order_url) rescue nil
            response_order_hash = JSON.parse(response_order) rescue {}
            order_count = response_order_hash["statistics"]["all"]["order_count"] rescue 0

            # item_detail.update_attributes!(:price => offer_price, :status => status, :last_verified_date => Time.now)
            item_detail.update_attributes!(:mrpprice => mrpprice, :price => offer_price, :status => status, :last_verified_date => Time.now, :offer => offer_text, :cashback => cashback, :description => effective_price, :shippingunit => order_count)
            image = item_detail.Image
          end

          begin
            if image.blank? && !image_url.blank?
              image = item_detail.build_image
              tempfile = open(image_url)
              avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile, :type => 'image/jpeg'})
              # filename = image_url.split("/").last
              filename = "#{item_detail.id}.jpeg"
              avatar.original_filename = filename
              image.avatar = avatar
              image.save
            end
          rescue Exception => e
            p e.backtrace
            p "There was a problem in image update"
            p "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            p source_item.url
          end
        end
      rescue Exception => e
        p "-----------------------------------------------------------"
        p "Error while processing paytm process"
      end
    end
  end

  def self.create_source_item_for_new_arrivals_from_amazon
    loop_hash = {"mobiles" => {:node => 1389432031, :page_count => 4}, "tablets" => {:node => 1375458031, :page_count => 4}, "cameras" => {:node => 1389175031, :page_count => 4}, "laptops" => {:node => 1375424031, :page_count => 4}, "lenses" => {:node => 1389197031, :page_count => 3}, "televisions" => {:node => 1389396031, :page_count => 3}, "video_games" => {:node => 4069183031, :page_count => 1}}

    loop_hash.each do |each_key, each_val|
      begin
        Sourceitem.get_and_create_sourceitem_from_amazon(each_val[:page_count], each_val[:node], each_key)
      rescue Exception => e
        p "Error while amazon api call"
      end
    end
  end

  def self.get_and_create_sourceitem_from_amazon(page_count, node, each_key=nil)
    [*1..page_count].each do |each_page|
      begin
        sleep(3)
        res = Amazon::Ecs.item_search("", {:response_group => 'Images,ItemAttributes,Offers', :country => 'us', :browse_node => node, :item_page => each_page, :sort => 'date-desc-rank'})

        items = res.items
        items.each do |each_item|
          begin
            url = each_item.get("DetailPageURL")
            begin
              url = URI.unescape(url)
              url = url.split("?")[0]
            rescue Exception => e
              url = url.split("%3F")[0]
            end
            id = each_item.get("ASIN").to_s.downcase rescue nil
            if id.blank?
              item_detail = Itemdetail.where(:url => url).first
            else
              item_detail = Itemdetail.where(:additional_details => id).first
              item_detail = Itemdetail.where(:url => url).first if item_detail.blank?
            end

            if !item_detail.blank?
              begin
                #price update
                offer_listing = each_item.get_element("Offers/Offer/OfferListing")
                offer_summary = each_item.get_element("OfferSummary")
                if !offer_listing.blank?
                  begin
                    current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  rescue Exception => e
                    current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  end
                  availability_str = offer_listing.get("Availability")

                  if availability_str.blank? && !offer_summary.blank?
                    current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue "" if current_price.blank?

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

                  item_detail.update_attributes!(:price => current_price, :status => status, :last_verified_date => Time.now)
                elsif !offer_summary.blank?
                  current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue ""

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
              rescue Exception => e
                p "Error while updating itemdetail => #{item_detail.id} price"
              end

              item = item_detail.item
              if !item.blank?
                update_all_amazon_itemdetails_of_item(item, item_detail)
                item_id = item_detail.itemid
                ad_item_id << item_id
              end
            else
              p "Not Included"
              p id
              p url

              next if 1 == 1 # TODO: have to fix

              begin
                id = each_item.get("ASIN").to_s.downcase rescue ""
                name = each_item.get_element("ItemAttributes").get("Title") rescue ""
                offer_listing = each_item.get_element("Offers/Offer/OfferListing")
                offer_summary = each_item.get_element("OfferSummary")
                current_price = nil
                status = 1
                image_url = each_item.get("LargeImage/URL") rescue nil
                if !offer_listing.blank?
                  begin
                    current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  rescue Exception => e
                    current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  end
                  availability_str = offer_listing.get("Availability")

                  if availability_str.blank? && !offer_summary.blank?
                    current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue "" if current_price.blank?

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
                elsif !offer_summary.blank?
                  current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue ""

                  total_new = offer_summary.get("TotalNew").to_i

                  if total_new > 0
                    status = 1
                  else
                    status = 0
                  end
                end

                item = Item.where(:name => each_key.camelize).first
                item_detail = Itemdetail.new(:itemid => item.id, :ItemName => name, :url => url, :price => current_price, :status => status, :iscashondeliveryavailable => false, :isemiavailable => false, :IsError => false, :additional_details => id, :site => "9882" )
                item_detail.save!

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
                  open(URI.parse(safe_thumbnail_url)) do |data|
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
                p "Error while creating itemdetail"
              end
            end
          rescue Exception => e
            p "Skip if there any error in item update"
          end
        end
      rescue Exception => e
        p "skip amazon api call error"
      end
    end
  end
end
