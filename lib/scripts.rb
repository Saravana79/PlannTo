## Change group name from one to another for product

csv_details = CSV.read("/home/sivakumar/gp_name_ch.csv")
csv_details.each_with_index do |csv_detail, index|
  next if index == 0
  p csv_detail
  item_id = csv_detail[0]
  old_related_item_name = csv_detail[3]
  related_item_name = csv_detail[4]
  item_relationship = Itemrelationship.find_or_initialize_by_item_id(item_id)
  related_item = CarGroup.find_or_initialize_by_name(related_item_name)
  if related_item.new_record?
    related_item.update_attributes(:itemtype_id => 5, :status => 1)
  end
  item_relationship.update_attributes(:relateditem_id => related_item.id, :relationtype => "CarGroup")
end


## Create product by Lens and update group

csv_details = CSV.read("/home/sivakumar/lens_import.csv")

csv_details.each_with_index do |csv_detail, index|
  next if index == 0
  p csv_detail
  name = csv_detail[0]
  related_item_name = csv_detail[2]
  item = Lens.find_or_initialize_by_name(name)
  item.itemtype_id = 20
  item.status = 1
  item.save!(:validate => false)

  if !related_item_name.blank?
    item_relationship = Itemrelationship.find_or_initialize_by_item_id(item.id)
    related_item = CarGroup.find_or_initialize_by_name(related_item_name)
    if related_item.new_record?
      related_item.update_attributes(:itemtype_id => 5, :status => 1)
    end
    item_relationship.update_attributes(:relateditem_id => related_item.id, :relationtype => "CarGroup")
  end
end



## Create product by Television and update group

csv_details = CSV.read("/home/sivakumar/television_import.csv")

csv_details.each_with_index do |csv_detail, index|
  next if index == 0
  p csv_detail
  name = csv_detail[0]
  related_item_name = csv_detail[1]
  item = Television.find_or_initialize_by_name(name)
  item.itemtype_id = 21
  item.status = 1
  item.save!(:validate => false)

  if !related_item_name.blank?
    item_relationship = Itemrelationship.find_or_initialize_by_item_id(item.id)
    related_item = CarGroup.find_or_initialize_by_name(related_item_name)
    if related_item.new_record?
      related_item.update_attributes(:itemtype_id => 5, :status => 1)
    end
    item_relationship.update_attributes(:relateditem_id => related_item.id, :relationtype => "CarGroup")
  end
end

## Create product by Car and update group

csv_details = CSV.read("/home/sivakumar/car.csv")
itemtype = "Car"
itemtype_id = Itemtype.find_by_itemtype(itemtype.camelize).id

csv_details.each_with_index do |csv_detail, index|
  next if index == 0
  p csv_detail
  name = csv_detail[0]
  related_item_name = csv_detail[1]
  image_name = csv_detail[2]
  item = itemtype.camelize.constantize.find_or_initialize_by_name(name)
  item.itemtype_id = itemtype_id
  item.status = 1
  item.imageurl = image_name
  item.save!(:validate => false)

  if !related_item_name.blank?
    item_relationship = Itemrelationship.find_or_initialize_by_item_id(item.id)
    related_item = CarGroup.find_or_initialize_by_name(related_item_name)
    if related_item.new_record?
      related_item.update_attributes(:itemtype_id => 5, :status => 1)
    end
    item_relationship.update_attributes(:relateditem_id => related_item.id, :relationtype => "CarGroup")
  end
end

## Create product by Bike

csv_details = CSV.read("/home/sivakumar/Newbikes.csv")
itemtype = "Bike"
itemtype_id = Itemtype.find_by_itemtype(itemtype.camelize).id

csv_details.each_with_index do |csv_detail, index|
  next if index == 0
  p csv_detail
  name = csv_detail[0]
  image_name = csv_detail[1]
  item = itemtype.camelize.constantize.find_or_initialize_by_name(name)
  item.itemtype_id = itemtype_id
  item.status = 1
  item.imageurl = image_name
  item.save!(:validate => false)
end


## Item loads from mysmartprice

require 'xmlsimple'
url = "http://www.mysmartprice.com/store_data/msp_master.xml"
xml_data = Net::HTTP.get_response(URI.parse(url)).body
data = XmlSimple.xml_in(xml_data)
items = data["channel"][0]["item"]
item_details = ActiveRecord::Base.connection.execute("update itemdetails set status = 4 where site = 26351")


items.each do |item|
  title = item["title"][0]
  product_type = item["product_type"][0].to_s.split(">")[1].to_s.strip
  url = item["link"][0]
  price = item["price"][0]
  image_url = item["image_link"][0]
  itemtype_hash = {"mobile" => 6, "laptops" => 23, "tablet" => 13}

  source_item = Sourceitem.find_or_initialize_by_url(url)
  if source_item.new_record?
    source_item.update_attributes(:name => title, :status => 1, :urlsource => "Mysmartprice", :itemtype_id => itemtype_hash[product_type], :created_by => "System", :verified => false)
  elsif source_item.verified && !source_item.matchitemid.blank?
    item_detail = Itemdetail.find_or_initialize_by_url(url)
    if item_detail.new_record?
      item_detail.update_attributes!(:ItemName => title, :itemid => source_item.id, :url => url, :price => price, :status => 1, :last_verified_date => Time.now, :site => 26351, :iscashondeliveryavailable => false, :isemiavailable => false)
      image = item_detail.Image
    else
      item_detail.update_attributes!(:price => price, status => 1, :last_verified_date => Time.now)
      image = item_detail.Image
    end
    if image.blank? && !image_url.blank?
      image = item_detail.build_image
      tempfile = open(image_url)
      avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile})
      filename = image_url.split("/").last
      avatar.original_filename = filename
      image.avatar = avatar
      image.save
    end
  end
end


## Create product by TV

csv_details = CSV.read("/home/sivakumar/Change in name_TV_21.csv")
itemtype = "Television"
itemtype_id = Itemtype.find_by_itemtype(itemtype.camelize).id

csv_details.each_with_index do |csv_detail, index|
  p csv_detail
  id = csv_detail[0]
  name = csv_detail[1]
  new_name = csv_detail[2]
  item = itemtype.camelize.constantize.find_by_id(id)
  if !item.blank?
    item.itemtype_id = itemtype_id
    item.name = new_name
    item.save!(:validate => false)
  end
end


## Beauty Products Creations
csv_details = CSV.read("/home/sivakumar/Desktop/new_beauty_products.csv")

csv_details.each do |each_rec|
  prev_item = nil
  each_rec.each do |item_name|
    next if item_name.blank?
    item = Beauty.find_or_initialize_by_name(item_name)
    item.update_attributes!(:imageurl => "#{item_name}.jpeg", :itemtype_id => 27, :status => 1)

    if !prev_item.blank?
      relation = Itemrelationship.find_or_initialize_by_item_id_and_relationtype(item.id, "Parent")
      relation.update_attributes(:relateditem_id => prev_item.id)
    end
    prev_item = item
  end
end


##Category Item detail for text links

csv_details = CSV.read("/home/sivakumar/Desktop/sports.csv", { :col_sep => "\t" })

category_item_details = []
csv_details.each_with_index do |csv_detail, index|
  next if index == 0

  category, sub_category, text, link = csv_detail

  next if category.blank?

  sub_category = "general" if sub_category.blank?
  category_item_detail = CategoryItemDetail.new(:item_type => "text links", :category => category.to_s.downcase, :sub_category => sub_category.to_s.downcase, :text => text, :link => link)
  category_item_details << category_item_detail
end

results = CategoryItemDetail.import(category_item_details)


##Category Item detail for product links

csv_details = CSV.read("/home/sivakumar/Desktop/sports_cwc.csv", { :col_sep => "\t" })

category_item_details = []
csv_details.each_with_index do |csv_detail, index|
  next if index == 0

  asin = csv_detail[0]

  category_item_detail = CategoryItemDetail.new(:item_type => "product links", :category => "sports", :sub_category => "cricket", :text => asin, :link => nil)
  category_item_details << category_item_detail
end

results = CategoryItemDetail.import(category_item_details)


## For Sify

csv_details = CSV.read("/home/sivakumar/Desktop/searches.csv", { :col_sep => "\t" })

category_item_details = []
csv_details.each_with_index do |csv_detail, index|
  next if index == 0

  sub_category = csv_detail[1]
  keyword = csv_detail[2]

  next if keyword.blank?

  category_item_detail = CategoryItemDetail.new(:item_type => "keyword links", :category => "general", :sub_category => sub_category, :text => keyword, :link => nil)
  category_item_details << category_item_detail
end

results = CategoryItemDetail.import(category_item_details)


# category list from stylecraze populate in feed urls

def get_article_urls(url, article_urls)
  uri = URI.parse(URI.encode(url.to_s.strip))
  doc = Nokogiri::HTML(open(uri, "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0", :allow_redirections => :all))

  articles = doc.xpath(".//article")

  articles.each do |article|
    begin
      article_urls << article.at(".entry-post-thumbnail")["href"]
    rescue Exception => e
      p e.backtrace
    end
  end
end

def process_category_lists(category_list)
  url = category_list[:url]
  count = category_list[:page_count]

  article_urls = []

  get_article_urls(url, article_urls)
  
  [*2..count].each do |page_no|
    tempurl = url + "page/#{page_no}"
    p "url => #{tempurl}"
    get_article_urls(tempurl, article_urls)
  end

  p article_urls.count
  sources_list = JSON.parse($redis.get("sources_list_details"))
  sources_list.default = "Others"
  process_url_to_feed_url(article_urls, sources_list)
end

def process_url_to_feed_url(article_urls, sources_list)
  admin_user = User.first
  article_urls.each do |url|
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

      category = sources_list[source]["categories"]

      new_feed_url = FeedUrl.new(feed_id: 43, url: url_for_save, title: title.to_s.strip, category: category,
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


category_lists = [ {:url => "http://www.stylecraze.com/articles/hair/", :page_count => 63}, {:url => "http://www.stylecraze.com/articles/skin/", :page_count => 101}]

category_lists.each do |category_list|
  process_category_lists(category_list)
end



# Junglee products update to Sourceitem

csv_details = CSV.read("/home/sivakumar/Desktop/jungle_products.csv", { :col_sep => "\t" })
false_items = []
csv_details.each_with_index do |csv_detail, index|
  next if index == 0

  itemtype_name = csv_detail[1].split("/").last.downcase
  itemtype_hash = {"mobiles" => 6, "laptops" => 23, "tablets" => 13, "netbooks" => 23}

  itemtype_id = itemtype_hash[itemtype_name]
  name = csv_detail[3]
  url = csv_detail[7]
  urlsource = "Junglee"
  status = 1
  verified = false

  s = Sourceitem.new(:name => name, :url => url, :urlsource => urlsource, :status => status, :verified => verified, :itemtype_id => itemtype_id, :created_by => "System")

  false_items << s if s.valid?
end

Sourceitem.import(false_items)


# Junglee products update to Sourceitem

csv_details = CSV.read(open("http://cdn1.plannto.com/test_folder/junglee_1.csv"))
valid_items = []
itemtype_hash = {"/Categories/Cameras & Accessories/Digital Cameras" => 12, "/Categories/Cameras & Accessories/Digital Cameras" => 12, "/Categories/Cameras & Accessories/Digital Cameras/Digital SLRs" => 12, "/Categories/Cameras & Accessories/Digital Cameras/Compact System Cameras" => 12, "/Categories/Cameras & Accessories/Digital Cameras/Point & Shoot Digital Cameras" => 12, "/Categories/Cameras & Accessories/Digital Cameras/Digital SLR Camera Bundles" => 12, "/Categories/Mobile Phones & Accessories/Mobile Phones" => 6}
csv_details.each_with_index do |csv_detail, index|
  next if index == 0

  # itemtype_name = csv_detail[1].split("/").last.downcase
  # itemtype_hash = {"mobiles" => 6, "laptops" => 23, "tablets" => 13, "netbooks" => 23}

  category = csv_detail[1]
  itemtype_id = itemtype_hash[category]
  name = csv_detail[3]
  url = csv_detail[7]
  urlsource = "Junglee"
  status = 1
  verified = false

  source_item = Sourceitem.where(:url => url, :itemtype_id => itemtype_id, :urlsource => urlsource)
  if source_item.blank?
    s = Sourceitem.new(:name => name, :url => url, :urlsource => urlsource, :status => status, :verified => verified, :itemtype_id => itemtype_id, :created_by => "System")

    valid_items << s if s.valid?
  end

end

Sourceitem.import(valid_items)


# update item_detail_other.rb

csv_details = CSV.read(open("http://planntonew.s3.amazonaws.com/test_folder/junglee_cars.csv"), { :col_sep => "\t" })
csv_details.each_with_index do |csv_detail, index|
  next if index == 0

  url = csv_detail[0]
  url = url.to_s
  url = "http://" + url if !url.include?("http")

  begin
    ItemDetailOther.update_item_detail_other_for_junglee(url)
  rescue Exception => e
    p e
  end
end

# Update google_content_category

csv_details = CSV.read("/home/sivakumar/skype/verticals.csv")
google_content_categories = []

csv_details.each_with_index do |csv_detail, index|
  next if index == 0

  category = csv_detail[0]
  category_id = csv_detail[1]
  parent_id = csv_detail[2]
  plannto_category = csv_detail[3]

  google_content_category = GoogleContentCategory.where(:category => category, :category_id => category_id).last

  if google_content_category.blank?
    google_content_category = GoogleContentCategory.new(:category => category, :category_id => category_id, :parent_id => parent_id, :plannto_category => plannto_category)
    google_content_categories << google_content_category
  end
end

GoogleContentCategory.import(google_content_categories)
