class Sourceitem < ActiveRecord::Base
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
    items = data["item"]

    items.each do |item|
      pid = item["pid"][0]
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
        source_item.update_attributes(:name => title, :status => 1, :urlsource => "Autoportal", :itemtype_id => 1, :created_by => "System", :verified => false)
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
            avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile})
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
end
