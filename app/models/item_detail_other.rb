class ItemDetailOther < ActiveRecord::Base
  has_many :item_detail_other_mappings
  has_one :image, as: :imageable
  belongs_to :vendor

  VALID_STATUS = 1
  EXPIRED_STATUS = 2
  INVALID_STATUS = 5

  attr_accessor :offer

  # For proptiger storing info
  # ad_detail1=possession,ad_detail2=livability_score,ad_detail3=status,ad_detail4=location

  def self.update_item_detail_other_for_junglee(url)
    # url ||= "http://www.junglee.com/dp/B00RGA4F3U"
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

    item_detail_other = ItemDetailOther.where(:url => url).last

    if item_detail_other.blank?
      item_detail_other = ItemDetailOther.new(:title => title, :price => price, :url => url, :status => status, :ad_detail1 => ad_detail1, :ad_detail2 => ad_detail2,
                                              :ad_detail3 => ad_detail3, :ad_detail4 => ad_detail4, :added_date => Date.today, :last_updated_at => Time.now)
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
        ItemDetailOtherMapping.create(:item_detail_other_id => item_detail_other.id, :item_id => item.id)
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
        ItemDetailOtherMapping.create(:item_detail_other_id => item_detail_other.id, :item_id => car.id)
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
        open(URI.parse(safe_thumbnail_url), :allow_redirections => :all) do |data|
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

    else
      item_detail_other.update_attributes(:price => price, :last_updated_at => Time.now)
    end
  end

  def self.update_item_detail_other_for_cardekho(url)
    # url ||= "http://www.junglee.com/dp/B00RGA4F3U"
    url = url.to_s
    url = "http://" + url if !url.include?("http")

    doc = Nokogiri::HTML(open(url, "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0"))
    node = doc.elements.first

    table = node.at_css(".usedleft")
    title_header = title.at_css(".headingbox")
    title = title_header.at_css(".indisplay h1").content rescue ""
    location_text = title_header.at_css(".dateused").content.split("|")[0].strip rescue ""
    location_text = node.at_css(".widthbreadcum").elements[4].content rescue "" if location_text.blank?
    # location_text = title
    price_text = node.at_css(".usedprice1").content rescue ""
    price_int = price_text.gsub(/[a-zA-Z]/, "").squish rescue ""
    price = price_int.to_f * 100000

    image_url = node.at_css(".usedphoto a img").attributes["data-original"].content rescue ""
    status = 1
    search_text = ""
    ad_detail1 = ""
    ad_detail2 = ""
    ad_detail3 = ""
    ad_detail4 = ""

    left_elements = node.at_css(".useddetailswrap .useddetleft").elements rescue []

    left_elements.each do |each_ele|
      type = each_ele.at_css(".usedl").content.to_s.squish rescue ""
      value = each_ele.at_css(".usedR").content.to_s.squish rescue ""

      next if type.blank?

      if type == "Km Driven"
        ad_detail2 = value
      elsif type == "Fuel Type"
        ad_detail1 = value
      end
    end

    right_elements = node.at_css(".useddetailswrap .useddetright").elements rescue []

    right_elements.each do |each_ele|
      type = each_ele.at_css(".usedl").content.to_s.squish rescue ""
      value = each_ele.at_css(".usedR").content.to_s.squish rescue ""

      next if type.blank?

      if type == "Transmission"
        ad_detail3 = value
      end
    end

    item_detail_other = ItemDetailOther.where(:url => url).last

    if item_detail_other.blank?
      item_detail_other = ItemDetailOther.new(:title => title, :price => price, :url => url, :status => status, :ad_detail1 => ad_detail1, :ad_detail2 => ad_detail2,
                                              :ad_detail3 => ad_detail3, :ad_detail4 => ad_detail4, :added_date => Date.today, :last_updated_at => Time.now)
      item_detail_other.save!

      @items = Sunspot.search([City,Place]) do
        keywords location_text do
          minimum_match 1
        end
        order_by :score,:desc
        order_by :orderbyid , :asc
        paginate(:page => 1, :per_page => 5)
      end

      item = @items.results.first rescue nil

      if !item.blank?
        ItemDetailOtherMapping.create(:item_detail_other_id => item_detail_other.id, :item_id => item.id)
      end

      cars = Sunspot.search([Car]) do
        keywords title do
          minimum_match 1
        end
        order_by :score,:desc
        order_by :orderbyid , :asc
        paginate(:page => 1, :per_page => 5)
      end

      car = cars.results.first rescue nil

      if !car.blank?
        ItemDetailOtherMapping.create(:item_detail_other_id => item_detail_other.id, :item_id => car.id)
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
        open(URI.parse(safe_thumbnail_url), :allow_redirections => :all) do |data|
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

    else
      item_detail_other.update_attributes(:price => price, :last_updated_at => Time.now)
    end
    item_detail_other
  end

  def self.get_item_detail_others_from_items_and_fashion_id(item_id, fashion_id=nil)
    item_ids = item_id.to_s.split(",")
    items = Item.where(:id => item_ids)
    if items.blank?
      return items, [], nil
    end
    location_ids = items.select {|each_val| each_val.is_a?(City)}.map(&:id)
    cars = items.select {|each_val| each_val.is_a?(Car)}
    car_ids = cars.map(&:id)

    location_condition = location_ids.blank? ? "and 1=1" : "and location_id in (#{location_ids.map(&:inspect).join(',')})"
    car_condition = car_ids.blank? ? "" : "select item_detail_other_id from item_detail_other_mappings where item_id in (#{car_ids.map(&:inspect).join(',')})"

    order_by_condition = " order by rand() limit 12"

    if car_condition.blank?
      query = "select * from item_detail_others where itemtype_id in (1) and status = 1  #{location_condition} #{order_by_condition}"
    else
      query = "select * from item_detail_others where id in (#{car_condition}) and itemtype_id in (1) and status = 1  #{location_condition} #{order_by_condition}"
    end
    item_details = ItemDetailOther.find_by_sql(query)

    # if !fashion_id.blank?
    #   item_details = Item.get_itemdetails_using_fashion_id(item_details, fashion_id)
    # else
    #   item_details = item_details.first(12)
    # end

    if item_details.count < 12
      query = "select * from item_detail_others where itemtype_id in (1) and status = 1 #{location_condition} limit 10"
      result_item_details = ItemDetailOther.find_by_sql(query)
      new_item_details = result_item_details - item_details
      item_details = item_details + new_item_details
    end
    car = cars.first

    car = Car.first if cars.blank?
    return items, item_details, car
  end

  def self.get_item_detail_others_from_items_and_fashion_id_for_property(item_id, fashion_id=nil)
    item_ids = item_id.to_s.split(",")
    items = Item.where(:id => item_ids)
    if items.blank?
      return items, [], nil
    end
    location_ids = items.select {|each_val| each_val.is_a?(City) || each_val.is_a?(Place)}.map(&:id)
    # cars = items.select {|each_val| each_val.is_a?(Car)}
    cars = items.select {|each_val| !each_val.is_a?(City) && !each_val.is_a?(Place)}
    car_ids = cars.map(&:id)

    location_condition = location_ids.blank? ? "and 1=1" : "and location_id in (#{location_ids.map(&:inspect).join(',')})"
    car_condition = car_ids.blank? ? "" : "select item_detail_other_id from item_detail_other_mappings where item_id in (#{car_ids.map(&:inspect).join(',')})"

    order_by_condition = " order by rand() limit 12"

    if car_condition.blank?
      query = "select * from item_detail_others where itemtype_id in (33) and status = 1  #{location_condition} #{order_by_condition}"
    else
      query = "select * from item_detail_others where id in (#{car_condition}) and itemtype_id in (33) and status = 1  #{location_condition} #{order_by_condition}"
    end

    p query

    item_details = ItemDetailOther.find_by_sql(query)

    # if !fashion_id.blank?
    #   item_details = Item.get_itemdetails_using_fashion_id(item_details, fashion_id)
    # else
    #   item_details = item_details.first(10)
    # end

    if item_details.count < 12
      query = "select * from item_detail_others where itemtype_id in (1) and status = 1 #{location_condition} limit 10"
      result_item_details = ItemDetailOther.find_by_sql(query)
      new_item_details = result_item_details - item_details
      item_details = item_details + new_item_details
    end
    car = cars.first

    car = Car.first if cars.blank?
    return items, item_details, car
  end

end
