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
      item_detail.update_attributes!(:ItemName => title, :itemid => source_item.matchitemid, :url => url, :price => price, :status => 1, :last_verified_date => Time.now, :site => 26351, :iscashondeliveryavailable => false, :isemiavailable => false)
      image = item_detail.Image
    else
      item_detail.update_attributes!(:price => price, status => 1, :last_verified_date => Time.now)
      image = item_detail.Image
    end
    if image.blank? && !image_url.blank?
      image = item_detail.build_image
      # tempfile = open(image_url)
      # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile, :type => 'image/jpeg'})
      # filename = image_url.split("/").last
      # avatar.original_filename = filename
      # image.avatar = avatar
      # image.save

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

      image.avatar = avatar
      if image.save
        item_detail.update_attributes(:Image => filename)
      end
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


csv_details = CSV.read("/home/sivakumar/skype/Latest_LW03-1.xlsx")

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
  # doc = Nokogiri::HTML(open(uri, "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0", :allow_redirections => :all))

  response_page = ""
  begin
    Timeout.timeout(25) do
      response_page = open(uri, "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0", :allow_redirections => :all)
    end
  rescue Exception => e
    response_page = ""
  end
  doc = Nokogiri::HTML(response_page)

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
  # sources_list = JSON.parse($redis.get("sources_list_details"))
  # sources_list.default = "Others"
  process_url_to_feed_url(article_urls, sources_list={})
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

      # category = sources_list[source]["categories"]

      category = SourceCategory.find_by_source(source).categories rescue ""
      category = "Others" if category.blank?

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


# Update google_content_category

csv_details = CSV.read("/home/sivakumar/skype/location.csv")
csv_details = CSV.read(open(url))
google_geo_targetings = []

csv_details.each_with_index do |csv_detail, index|
  next if index == 0

  criteria_id = csv_detail[0]
  name = csv_detail[1]
  canonical_name = csv_detail[2]
  parent_id = csv_detail[3]
  country_code = csv_detail[4]
  target_type = csv_detail[5]
  status = csv_detail[6]

  # google_geo_targetings = GoogleGeoTargeting.where(:criteria_id => criteria_id).last

  google_geo_targeting = GoogleGeoTargeting.new(:criteria_id => criteria_id, :name => name, :canonical_name => canonical_name, :parent_id => parent_id,
                                                :country_code => country_code, :target_type => target_type, :status => status)

  if country_code == "IN"
    places = Sunspot.search([City,Place]) do
      keywords name do
        minimum_match 1
      end
      order_by :score,:desc
      order_by :orderbyid , :asc
      paginate(:page => 1, :per_page => 5)
    end

    city = places.results.first rescue nil
    score = places.hits.first.score.to_f rescue 0

    google_geo_targeting.location_id = city.id if (!city.blank? && score > 1)

    google_geo_targetings << google_geo_targeting
  else
    google_geo_targetings << google_geo_targeting
  end

  if google_geo_targetings.count > 10000
    GoogleGeoTargeting.import(google_geo_targetings)
    google_geo_targetings = []
  end
end

GoogleGeoTargeting.import(google_geo_targetings)


url = "http://indiatoday.intoday.in/technology/story/zte-nubia-z9-mini-review-camera-and-battery-life-make-it-a-superstar/1/444641.html"
url = "http://indiatoday.intoday.in/technology/story/microsoft-lumia-540-review-windows-phone-smartphone/1/443370.html"

doc = Nokogiri::HTML(open(url))
match_words = []

node = doc.elements.first

[*0..3].each do |each_val|
  term = node.css(".hub-caption p")[3].content rescue ""

  removed_keywords = ["difference", "between", "of", "and ", "is", "a", "an", "the", "how", "to", "must", "have", "top", "10", "when", "fashion", "tale", "here", "new",
                      "innovative", "style", "store", "preserve", "way", "rs ", "you", "are","simple","choose","right","for","does", "gorgeous", "amazing", "benefit", "health","things", "should", "their", "unforgettable", "stylish","home",
                      "get","goddess","look","with","uses","available", "india", "job ","remedies", "most", "expensive", "product","lose","weight", "help","reason","larger","each","season","treat","every","guide","need","know","side","effects",
                      "prevent","exercise","sick","delicious","apply","perfectly", "and","step","get","tutorial","picture","detailed","article","surprising","prepare","indian","in","best","using","at","everything","from","natural","your","basic",
                      "wear","diy","kiss","woes","good","bye","homemade","wearing","avoid","while","mistake","wonderful","hide","make","sure","cause", "it", "on", "i", "we", "was"]
  term = term.gsub("-"," ")
  term = term.to_s.split(/\W+/).delete_if{|x| (removed_keywords.include?(x.to_s.downcase.strip) || x.length < 2) || removed_keywords.include?(Item.remove_last_letter_as_s(x.to_s.downcase)) }.join(' ')
  #term = term.to_s.split(/\W+/).delete_if{|x| (x =~ /\D/).blank? }.join(' ')

  terms = term.to_s.split(/\W+/)

  terms_splt = terms.each_slice(12)

  terms_splt.each do |each_terms|
    splt_term = each_terms.join(" ")

    @items = Sunspot.search([Mobile]) do
      keywords splt_term do
        minimum_match 1
      end
      with :status, [1,2,3]
      order_by :score,:desc
      order_by :orderbyid , :asc
      paginate(:page => 1, :per_page => 5)
    end

    item = @items.results.first

    score = @items.hits.first.score.to_f rescue 0
    match_words << item if score > 0.5
  end
end


# UPdate apparel and style

filename = "/home/sivakumar/skype/Latest_LW03-1.txt"
csv_details = CSV.read(filename, { :col_sep => "\t" })


csv_details.each do |each_val|
  apparel_name = each_val[0]
  style_name = each_val[1]

  if !apparel_name.blank?
    item = Apparel.find_or_initialize_by_name(apparel_name)
    item.update_attributes!(:imageurl => "#{apparel_name}.jpeg", :itemtype_id => 52, :status => 1, :created_by => 1) rescue apparel_name
  end

  if !style_name.blank?
    item = Style.find_or_initialize_by_name(style_name)
    item.update_attributes!(:imageurl => "#{style_name}.jpeg", :itemtype_id => 53, :status => 1, :created_by => 1) rescue style_name
  end
end



filename = "/home/sivakumar/Downloads/DealsSample.xlsx"
filename = "http://planntonew.s3.amazonaws.com/test_folder/DealsSample.xlsx"
xlsx = Roo::Spreadsheet.open(open(filename))
deal_items = []
xlsx.each_with_index do |each_row, indx|
  if indx == 0
    headers = each_row
    next
  end

  deal_items << DealItem.new(:deal_id => each_row[0], :deal_type => each_row[1], :deal_state => each_row[2], :category => each_row[3], :asin => each_row[4], :deal_title => each_row[5], :start_time => each_row[6], :end_time => each_row[7], :list_price => each_row[8], :deal_price => each_row[9], :discount => ((each_row[10].blank? || each_row[10] == "NA") ? nil : each_row[10]), :url => each_row[11], :image_url => each_row[12], :browse_node_id1 => each_row[13], :sub_category_path1 => each_row[14], :browse_node_id2 => each_row[15], :sub_category_path2 => each_row[16], :last_updated_at => Time.now)
end

DealItem.import(deal_items)


require 'xmlsimple'
url = "http://autoportal.com/vizury_feed.xml"
xml_data = Net::HTTP.get_response(URI.parse(url)).body
data = XmlSimple.xml_in(xml_data)
items = data["item"]
source_items = []

items.each do |item|
  title = item["pname"][0]
  url = item["landing_page"][0]

  source_item = Sourceitem.new(:url => url, :name => title, :status => 1, :urlsource => "Autoportal", :itemtype_id => 1, :created_by => "System", :verified => false)

  source_items << source_item
end

Sourceitem.import(source_items)


#Update itemdetails for Autoportal

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
        # tempfile = open(image_url)
        # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile, :type => 'image/jpeg'})
        # filename = image_url.split("/").last
        # avatar.original_filename = filename
        # image.avatar = avatar
        # image.save

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

        image.avatar = avatar
        if image.save
          item_detail.update_attributes(:Image => filename)
        end
      end
    rescue Exception => e
      p "There was a problem in image update"
    end
  end
end


url = "https://assoc-datafeeds-eu.amazon.com/datafeed/getFeed?filename=in_amazon_df_deals.csv.gz"
xml_response = OrderHistory.get_order_details_from_amazon(url, "pla04", "cyn04")
deal_items = []

xml_response.split("\n").each_with_index do |each_row, indx|
  each_row = each_row.split(",")
  if indx == 0
    headers = each_row
    next
  end

  url = each_row[11].to_s.gsub(/["\\]/,'')
  deal_item = DealItem.where(:url => url).last

  if !deal_item.blank?
    deal_item.update_attributes(:deal_id => each_row[0].to_s.gsub(/["\\]/,''), :deal_type => each_row[1].to_s.gsub(/["\\]/,''), :deal_state => each_row[2].to_s.gsub(/["\\]/,''), :category => each_row[3].to_s.gsub(/["\\]/,''), :asin => each_row[4].to_s.gsub(/["\\]/,''), :deal_title => each_row[5].to_s.gsub(/["\\]/,''), :start_time => each_row[6].to_s.gsub(/["\\]/,''), :end_time => each_row[7].to_s.gsub(/["\\]/,''), :list_price => each_row[8].to_s.gsub(/["\\]/,''), :deal_price => each_row[9].to_s.gsub(/["\\]/,''), :discount => ((each_row[10].to_s.gsub(/["\\]/,'').blank? || each_row[10].to_s.gsub(/["\\]/,'') == "NA") ? nil : each_row[10].to_s.gsub(/["\\]/,'')), :image_url => each_row[12].to_s.gsub(/["\\]/,''), :browse_node_id1 => each_row[13].to_s.gsub(/["\\]/,''), :sub_category_path1 => each_row[14].to_s.gsub(/["\\]/,''), :browse_node_id2 => each_row[15].to_s.gsub(/["\\]/,''), :sub_category_path2 => each_row[16].to_s.gsub(/["\\]/,''), :last_updated_at => Time.now)
  else
    deal_items << DealItem.new(:deal_id => each_row[0].to_s.gsub(/["\\]/,''), :deal_type => each_row[1].to_s.gsub(/["\\]/,''), :deal_state => each_row[2].to_s.gsub(/["\\]/,''), :category => each_row[3].to_s.gsub(/["\\]/,''), :asin => each_row[4].to_s.gsub(/["\\]/,''), :deal_title => each_row[5].to_s.gsub(/["\\]/,''), :start_time => each_row[6].to_s.gsub(/["\\]/,''), :end_time => each_row[7].to_s.gsub(/["\\]/,''), :list_price => each_row[8].to_s.gsub(/["\\]/,''), :deal_price => each_row[9].to_s.gsub(/["\\]/,''), :discount => ((each_row[10].to_s.gsub(/["\\]/,'').blank? || each_row[10].to_s.gsub(/["\\]/,'') == "NA") ? nil : each_row[10].to_s.gsub(/["\\]/,'')), :url => each_row[11].to_s.gsub(/["\\]/,''), :image_url => each_row[12].to_s.gsub(/["\\]/,''), :browse_node_id1 => each_row[13].to_s.gsub(/["\\]/,''), :sub_category_path1 => each_row[14].to_s.gsub(/["\\]/,''), :browse_node_id2 => each_row[15].to_s.gsub(/["\\]/,''), :sub_category_path2 => each_row[16].to_s.gsub(/["\\]/,''), :last_updated_at => Time.now)
  end
end

DealItem.import(deal_items)





url = "/home/sivakumar/Downloads/feed.xml"
# url = "https://s3-ap-southeast-1.amazonaws.com/paytmreports/googlepla/feed.xml.gz"
each_node_list = Nokogiri::XML::Reader(File.open(url)).first
each_node_list = doc = Nokogiri::XML(File.open(url))

# each_node_list.first
product_types = []
source_items = []
each_node_list.each_with_index do |each_node, index|
  begin
    p index += 1
    # logger.info index += 1
    if each_node.local_name == "item"
      p "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
      # logger.info "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
      outer_item_xml = each_node.outer_xml

      p xml_hash = XmlSimple.xml_in(outer_item_xml)
      product_type = xml_hash["product_type"][0] rescue ""
      p product_type = product_type.split(">").last.strip rescue ""
      if ["Mobiles", "Tablets", "Laptops", "DSLR", "Point & Shoot"].include?(product_type)
        p "-------------------------------------------------------------------------------"
        # logger.info "-------------------------------------------------------------------------------"
        p product_type
        # logger.info product_type
        product_types << product_type
        product_types = product_types.uniq
        p "success"
        # logger.info "success"
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

        status = (xml_hash["availability"][0].to_s.include?("in stock") ? 1 : 2) rescue 2

        mrpprice = xml_hash["price"][0].to_s.gsub("INR", "").strip rescue ""
        price = xml_hash["sale_price"][0].to_s.gsub("INR", "").strip rescue ""
        mpn = xml_hash["mpn"][0].to_s rescue ""
        description = xml_hash["description"][0].to_s rescue ""
        image_url = xml_hash["image_link"][0].to_s rescue ""

        # cashback = FeedUrl.get_value_from_pattern(offer.to_s.downcase, "rs<price>cashback", "<price>").strip rescue ""
        # isemiavailable = offer.to_s.downcase.include?("emi available") ? true : false

        source_item = Sourceitem.find_or_initialize_by_url(url)
        if source_item.new_record?
          source_item.update_attributes(:name => title, :status => 1, :urlsource => "Paytm", :itemtype_id => itemtype_id, :created_by => "System", :verified => false, :additional_details => mpn)
          # elsif source_item.verified && !source_item.matchitemid.blank?
          #   item_detail = Itemdetail.find_or_initialize_by_url(url)
          #   if item_detail.new_record?
          #     item_detail.update_attributes!(:ItemName => title, :itemid => source_item.matchitemid, :url => url, :price => price, :status => status, :last_verified_date => Time.now, :site => 76201, :iscashondeliveryavailable => false, :isemiavailable => false, :additional_details => mpn, :cashback => 0, :description => description, :IsError => false, :mrpprice => mrpprice)
          #     image = item_detail.Image
          #   else
          #     item_detail.update_attributes!(:price => price, :status => 1, :last_verified_date => Time.now)
          #     image = item_detail.Image
          #   end
          #   begin
          #     if image.blank? && !image_url.blank?
          #       image = item_detail.build_image
          #       tempfile = open(image_url)
          #       avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile, :type => 'image/jpeg'})
          #       filename = image_url.split("/").last
          #       avatar.original_filename = filename
          #       image.avatar = avatar
          #       image.save
          #     end
          #   rescue Exception => e
          #     p "There was a problem in image update"
          #   end
        end


        # source_item = Sourceitem.new(:url => url, :name => title, :status => 1, :urlsource => "Paytm", :itemtype_id => itemtype_id, :created_by => "System", :verified => false)
        #
        # source_items << source_item
        #
        # if source_items.count > 20
        #   # Sourceitem.import(source_items)
        #   source_items = []
        # end
      end
    end
  rescue Exception => e
    p e
    p "3333333333333333"
    p product_types
  end
end


source_items = Sourceitem.where("verified=true and matchitemid is not null and url like '%paytm.com%'")

source_items.each do |source_item|
  if source_item.verified && !source_item.matchitemid.blank?
    json_url = "https://catalog.paytm.com/v1/p/" + source_item.url.to_s.split("/").last
    response = RestClient.get(json_url)

    response_hash = JSON.parse(response) rescue {}

    product_id = response_hash["product_id"] rescue ""
    image_url = response_hash["image_url"] rescue ""
    status = response_hash["status"] == true ? 1 : 2
    offer = response_hash["promo_text"] rescue ""
    title = response_hash["name"] rescue ""
    mrpprice = response_hash["actual_price"] rescue ""
    offer_price = response_hash["offer_price"] rescue ""
    description = response_hash["meta_description"] rescue ""
    cashback = FeedUrl.get_value_from_pattern(offer.to_s.downcase, "rs<price>cashback", "<price>").strip rescue ""
    isemiavailable = offer.to_s.downcase.include?("emi available") ? true : false
    iscashondeliveryavailable = offer.to_s.downcase.include?("cod option will be available") ? true : false

    item_detail = Itemdetail.find_or_initialize_by_url(source_item.url)
    if item_detail.new_record?
      item_detail.update_attributes!(:ItemName => title, :itemid => source_item.matchitemid, :url => source_item.url, :price => offer_price, :status => status, :last_verified_date => Time.now, :site => 76201, :iscashondeliveryavailable => iscashondeliveryavailable, :isemiavailable => isemiavailable, :additional_details => product_id, :cashback => cashback, :description => description, :IsError => false, :mrpprice => mrpprice, :offer => offer)
      image = item_detail.Image
    else
      item_detail.update_attributes!(:price => offer_price, :status => status, :last_verified_date => Time.now)
      image = item_detail.Image
    end

    begin
      if image.blank? && !image_url.blank?
        image = item_detail.build_image
        # tempfile = open(image_url)
        # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile, :type => 'image/jpeg'})
        # # filename = image_url.split("/").last
        # filename = "#{item_detail.id}.jpeg"
        # avatar.original_filename = filename
        # image.avatar = avatar
        # image.save

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

        image.avatar = avatar
        if image.save
          item_detail.update_attributes(:Image => filename)
        end
      end
    rescue Exception => e
      p e.backtrace
      p "There was a problem in image update"
      p "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
      p source_item.url
    end
  end
end




# Update sourceitem from paytm

require 'rubygems'
require 'nokogiri'

class MyDocument < Nokogiri::XML::SAX::Document
  def initialize
    @open_struct = OpenStruct.new
    @i = 0
  end

  def start_element(name, attrs)
    @attrs = attrs
    @content = ''
    @i += 1
    #@open_struct = OpenStruct.new
  end

  def end_element(name)
    p @i
    @open_struct.title = @content if name == 'title'
    @open_struct.product_type = @content if name == "g:product_type"
    if name == "link"
      @open_struct.url = @content
      # p @open_struct.title
      # p @open_struct.product_type
      # p @open_struct.url

      product_type = @open_struct.product_type.split(">").last.strip rescue ""

      itemtype_id = case product_type
                      when "Mobiles"
                        6
                      when "Tablets"
                        13
                      when "Laptops"
                        23
                      when "DSLR", "Point & Shoot"
                        12
                      else
                        0
                    end

      if itemtype_id != 0
        source_item = Sourceitem.find_or_initialize_by_url(@open_struct.url)

        if source_item.new_record?
          p "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
          p source_item.url
          p @open_struct.title
          source_item.update_attributes(:name => @open_struct.title, :status => 1, :urlsource => "Paytm", :itemtype_id => itemtype_id, :created_by => "System", :verified => false)
        end
      end
    end
    @content = nil
  end

  def characters(string)
    @content << string if @content
  end

  def cdata_block(string)
    characters(string)
  end
end

parser = Nokogiri::XML::SAX::Parser.new(MyDocument.new)
parser.parse_file("/home/sivakumar/Downloads/feed.xml")


# kavoos item beauty detail update

data = XmlSimple.xml_in(File.open("/home/sivakumar/skype/335-21092015-085816.xml"))

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
          Timeout.timeout(25) do
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
        # tempfile = open(image_url)
        # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile, :type => 'image/jpeg'})
        # # filename = image_url.split("/").last
        # filename = "#{item_beauty_detail.id}.jpeg"
        # avatar.original_filename = filename
        # image.avatar = avatar
        # image.save

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

        image.avatar = avatar
        if image.save
          item_detail.update_attributes(:Image => filename)
        end
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


jockey_hash = {"men" => {"innerwear-bottoms" => 76609, "innerwear-tops" => 76610, "outerwear-bottoms" => 76611, "outerwear-tops" => 75427, "socks" => 75524}, "women" => {"bras" => 75520, "panties" => 76607, "camisoles-and-tops" => 75438, "outerwear-bottoms" => 76608, "shapewear" => 75522}}
base_url = "http://www.jockeyindia.com"

jockey_hash.each do |int_key, int_val|
  type_base_url = base_url + "/#{int_key}/"

  int_val.each do |key, val|
    p url = type_base_url + key

    doc = Nokogiri::HTML(open(url))

    products = doc.search(".products_container_women .pro1 .thumbs_container_new_topBox")

    p "+++++++++++++++++++++++++++++++++++Total Count #{products.count}+++++++++++++++++++++++++++++++++++++++++++++++++"
    processed_count = 0
    products.each do |each_product|
      begin
        url_text = each_product.css("a").first.attributes["href"].text rescue ""
        next if url_text.blank?
        url_link = base_url + url_text
        image_url = each_product.css(".img_border_details_new_1").at(".img_quickviewLoader").attributes["src"].text rescue ""
        title = each_product.css(".img_border_details_new_1").at(".img_quickviewLoader").attributes["alt"].text  rescue ""

        price = each_product.css(".details_1_new .pricedetailswithstylecode").at(".price_rs").inner_text.to_s.downcase.gsub("rs.", '').gsub(",", "") rescue ""
        style_code = each_product.css(".details_1_new .pricedetailswithstylecode").at(".style_code").inner_text.to_s.downcase.gsub("style # ", '') rescue ""

        p item_detail = Itemdetail.find_or_initialize_by_url(url_link)

        if item_detail.new_record?
          item_detail.update_attributes!(:ItemName => title, :itemid => val, :url => url_link, :price => price, :status => 1, :last_verified_date => Time.now, :site => 76612, :iscashondeliveryavailable => false, :isemiavailable => false, :additional_details => style_code, :cashback => "", :description => "", :IsError => false, :mrpprice => price, :offer => "")
          image = item_detail.image
        else
          item_detail.update_attributes!(:price => price, :status => 1, :last_verified_date => Time.now)
          image = item_detail.image
        end

        begin
          if image.blank? && !image_url.blank?
            image = item_detail.build_image
            # tempfile = open(image_url)
            # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile, :type => 'image/jpeg'})
            # # filename = image_url.split("/").last
            # filename = "#{item_detail.id}.jpeg"
            # avatar.original_filename = filename
            # image.avatar = avatar
            # image.save

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

            image.avatar = avatar
            if image.save
              item_detail.update_attributes(:Image => filename)
            end
          end
        rescue Exception => e
          p e.backtrace
          p "There was a problem in image update"
          p url_link
        end
        processed_count += 1
      rescue Exception => e
        p "There was a problem while updating product #{url}"
        break
      end
    end
    p "--------------------------------------------- Processed Count #{processed_count} ---------------------------------------------"
  end
end


# sources_list = JSON.parse($redis.get("sources_list_details"))
# sources_list.default = "Others"

url = "http://planntonew.s3.amazonaws.com/test_folder/mobile_products_catalog.csv"
csv_details = CSV.read(url)

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

    category = SourceCategory.find_by_source(source).categories rescue ""
    category = "Others" if category.blank?

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


# conversion_pixel_detail order update

# conversion_pixel_details = ConversionPixelDetail.where("source='mi' and conversion_time > '2016-02-04'")
#
# conversion_pixel_details.each do |conversion_pixel_detail|
#   p Click.where(:temp_user_id => conversion_pixel_detail.plannto_user_id)
# end

clicks = Click.where(:advertisement_id => 83)

clicks.each do |click|
  conversion_pixel_details = ConversionPixelDetail.where(:plannto_user_id => click.temp_user_id, :from_plannto => false)
  conversion_pixel_details.each do |conversion_pixel_detail|
    conversion_pixel_detail.from_plannto = true
    conversion_pixel_detail.save
  end
end



#Aggregated Detail update
order_histories = OrderHistory.where("date(order_date) > '2016-1-1' and order_status='Validated'")

order_histories.each do |order_history|
  p order_history
  impression = AddImpression.where(:id => order_history.impression_id).last
  if !impression.blank?
    time = impression.impression_time.to_time.utc rescue Time.now
    date = time.to_date rescue ""
    agg_imp = AggregatedImpression.where(:agg_date => date, :ad_id => order_history.advertisement_id).last
    price = order_history.product_price.to_s.gsub("," , "").to_f

    agg_imp.tot_valid_orders = agg_imp.tot_valid_orders.to_i + 1
    agg_imp.tot_valid_product_price = agg_imp.tot_valid_product_price.to_f + price

    agg_imp.save!
  end
end


item_detail_others = ItemDetailOther.where(:itemtype_id => 33)

item_details_other = item_details_others.last

url = item_details_other.url
doc = Nokogiri::HTML(open(url))

doc.css(".prop-price-info")



# Amazon product update

# url = "https://pla04:cyn04@assoc-datafeeds-eu.amazon.com/datafeed/getFeed?filename=in_amazon_kindle.xml.gz"
# url = "https://assoc-datafeeds-eu.amazon.com/datafeed/getFeed?filename=in_amazon_kindle.xml.gz"
url = "https://assoc-datafeeds-eu.amazon.com/datafeed/getFeed?filename=in_amazon_ce.xml.gz"

digest_auth = Net::HTTP::DigestAuth.new

uri = URI.parse(url)
uri.user = "pla04"
uri.password = "cyn04"

h = Net::HTTP.new uri.host, uri.port
h.use_ssl = true
h.ssl_version = :TLSv1

req = Net::HTTP::Get.new uri.request_uri

res = h.request req
# res is a 401 response with a WWW-Authenticate header

auth = digest_auth.auth_header uri, res['www-authenticate'], 'GET'

# create a new request with the Authorization header
req = Net::HTTP::Get.new uri.request_uri
req.add_field 'Authorization', auth

# re-issue request with Authorization
res = h.request req

if res.kind_of?(Net::HTTPFound)
  location = res["location"]
  infile = open(location)
  gz = Zlib::GzipReader.new(infile)

  each_node_list = Nokogiri::XML::Reader(gz).first

  each_node_list.first
  product_types = []
  source_items = []
  item_categories = []
  each_node_list.each_with_index do |each_node, index|
    if each_node.local_name == "item_data"
      outer_xml = each_node.outer_xml
      hash = XmlSimple.xml_in(outer_xml)
      if !hash.blank?
        basic_data = hash["item_basic_data"][0]
        item_category = basic_data["item_category"][0]

        if basic_data["item_name"].to_s.include?("Apple iPhone 5s (Gold, 16GB)")
          p 11111111111111111
          p outer_xml
        end

        if item_categories.exclude?(item_category)
          item_categories << item_category
          p 222222222222
          p item_categories
        end
      end
    end
  end
else
  p "Try Different format - Its not working"
end





# Update sourceitem from amazon with SAX parser
url = "https://assoc-datafeeds-eu.amazon.com/datafeed/getFeed?filename=in_amazon_ce.xml.gz"

digest_auth = Net::HTTP::DigestAuth.new

uri = URI.parse(url)
uri.user = "pla04"
uri.password = "cyn04"

h = Net::HTTP.new uri.host, uri.port
h.use_ssl = true
h.ssl_version = :TLSv1

req = Net::HTTP::Get.new uri.request_uri

res = h.request req
# res is a 401 response with a WWW-Authenticate header

auth = digest_auth.auth_header uri, res['www-authenticate'], 'GET'

# create a new request with the Authorization header
req = Net::HTTP::Get.new uri.request_uri
req.add_field 'Authorization', auth

# re-issue request with Authorization
res = h.request req

if res.kind_of?(Net::HTTPFound)
  location = res["location"]
  infile = open(location)
  gz = Zlib::GzipReader.new(infile)

  require 'rubygems'
  require 'nokogiri'

  class MyDocument < Nokogiri::XML::SAX::Document
    def initialize
      @open_struct = OpenStruct.new
      @contents = []
      @i = 0
    end

    def start_element(name, attrs)
      @attrs = attrs
      @content = ''
      @i += 1
      #@open_struct = OpenStruct.new
    end

    def end_element(name)
      @open_struct.item_unique_id = @content if name == 'item_unique_id'
      @open_struct.title = @content if name == 'item_name'
      if name == 'item_page_url'
        item_page_url = @content
        # item_page_url = Item.amazon_formatted_url(item_page_url)
        formatted_url = item_page_url.match(/(.*).*\/ref\/*/)
        item_page_url = formatted_url[1]
        @open_struct.url = item_page_url
      end
      if name == 'merch_cat_name'
        merch_cat_name = @content
        @open_struct.merch_cat_name = @content

        itemtype_id = case merch_cat_name
                        when "1805559031", "1805560031" #"Mobiles"
                          6
                        when "1375458031" #"Tablets"
                          13
                        when "1375424031" #"Laptops"
                          23
                        when "1389177031", "1389181031" #"DSLR", "Point & Shoot"
                          12
                        else
                          0
                      end

        if itemtype_id != 0 && !@open_struct.item_unique_id.to_s.blank?
          # p @open_struct.item_unique_id
          # p @open_struct.title
          # p @open_struct.url
          # p itemtype_id
          source_item = Sourceitem.find_or_initialize_by_additional_details(@open_struct.item_unique_id)

          if source_item.new_record?
            p "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            p source_item.additional_details
            p @open_struct.title
            source_item.update_attributes(:name => @open_struct.title, :url => @open_struct.url, :status => 2, :urlsource => "Amazon", :itemtype_id => itemtype_id, :created_by => "System", :verified => false)
          end
        end

      end
      # #@open_struct.product_type = @content if name == "item_category"
      #
      # # if @open_struct.title.to_s.include?("Apple iPhone 5s (Gold, 16GB)")
      # # if @open_struct.item_unique_id == ""
      # if @open_struct.item_unique_id == "B00FXLCD38"
      #   p "#{name} => #{@content}"
      # end

      # if name == "item_category"
      #   if @open_struct.title.to_s.include?("Apple iPhone 5s (Gold, 16GB)")
      #     p @open_struct.title
      #     p @content
      #   end
      #   # if @contents.exclude?(@content)
      #   #   @contents << @content
      #   #   p @i
      #   #   p @contents
      #   # end
      #   # @open_struct.url = @content
      #   # p @open_struct.title
      #   # p @open_struct.product_type
      #   # p @open_struct.url
      #
      #   #product_type = @open_struct.product_type.split(">").last.strip rescue ""
      #
      #   # itemtype_id = case product_type
      #   #                 when "Mobiles"
      #   #                   6
      #   #                 when "Tablets"
      #   #                   13
      #   #                 when "Laptops"
      #   #                   23
      #   #                 when "DSLR", "Point & Shoot"
      #   #                   12
      #   #                 else
      #   #                   0
      #   #               end
      #
      #   # if itemtype_id != 0
      #   #   source_item = Sourceitem.find_or_initialize_by_url(@open_struct.url)
      #
      #   #   if source_item.new_record?
      #   #     p "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
      #   #     p source_item.url
      #   #     p @open_struct.title
      #   #     source_item.update_attributes(:name => @open_struct.title, :status => 1, :urlsource => "Paytm", :itemtype_id => itemtype_id, :created_by => "System", :verified => false)
      #   #   end
      #   # end
      # end
      @content = nil
    end

    def characters(string)
      @content << string if @content
    end

    def cdata_block(string)
      characters(string)
    end
  end

  parser = Nokogiri::XML::SAX::Parser.new(MyDocument.new)
  parser.parse(gz)
else
  p "Try Different format - Its not working"
end


#remove CookieMatch old records of last 2 months

query = "select * from cookie_matches where updated_at < '#{2.month.ago}'"
batch_size = 10000

page = 1
begin
  cookie_matches = CookieMatch.paginate_by_sql(query, :page => page, :per_page => batch_size).delete_all

  # cookie_matches.delete_all
  page += 1
end while !cookie_matches.empty?


CookieMatch.find_in_batches(:batch_size => 10000) do |cookie_matches|
  sel_cookie_matches = cookie_matches.select {|each_record| each_record.updated_at < 2.year.ago}
  p sel_cookie_matches.count
  sel_cookie_matches.each {|d| d.delete}
end


# aggregation of 
start_date = (Date.today - 1.days).beginning_of_day
start_date = Date.today.beginning_of_day

unwind = { :"$unwind" => "$i_types" }
unwind1 = { :"$unwind" => "$i_types.m_items" }
match = {"$match" => {"lad" => {"$gte" => start_date}}}
group =  { "$group" => { "_id" => "$i_types.m_items.item_id", "imp_count" => { "$sum" => 1 } } }


Benchmark.ms do
  pp = PUserDetail.collection.aggregate([unwind,unwind1,match,group])
end



keys = $redis_rtb.keys("imp:*")

keys = $redis_rtb.keys("imp:#{Date.today}*")



PUserDetail.where(:lad.gte => Date.today).count




start_date = (Date.today - 1.days).beginning_of_day
start_date = Date.today.beginning_of_day

# unwind = { :"$unwind" => "$i_types" }
# unwind1 = { :"$unwind" => "$i_types.m_items" }
match = {"$match" => {"lad" => {"$gte" => start_date}}}
# group =  { "$group" => { "_id" => "$i_types.m_items.item_id", "imp_count" => { "$sum" => 1 } } }
pp = PUserDetail.collection.aggregate([match])

# Benchmark.ms do
#   pp = PUserDetail.collection.aggregate([match])
# end

plannto_user_details = PUserDetail.where(:lad.gte => start_date)







#New Implementation for apperal


# Update sourceitem from amazon with SAX parser
url = "https://assoc-datafeeds-eu.amazon.com/datafeed/getFeed?filename=in_amazon_apparel.xml.gz"

digest_auth = Net::HTTP::DigestAuth.new

uri = URI.parse(url)
uri.user = "pla04"
uri.password = "cyn04"

h = Net::HTTP.new uri.host, uri.port
h.use_ssl = true
h.ssl_version = :TLSv1

req = Net::HTTP::Get.new uri.request_uri

res = h.request req
# res is a 401 response with a WWW-Authenticate header

auth = digest_auth.auth_header uri, res['www-authenticate'], 'GET'

# create a new request with the Authorization header
req = Net::HTTP::Get.new uri.request_uri
req.add_field 'Authorization', auth

# re-issue request with Authorization
res = h.request req

if res.kind_of?(Net::HTTPFound)
  location = res["location"]
  infile = open(location)
  gz = Zlib::GzipReader.new(infile)
  @@main_array = []
  @@header_set = false

  require 'rubygems'
  require 'nokogiri'

  class MyDocument < Nokogiri::XML::SAX::Document
    def initialize
      @open_struct = OpenStruct.new
      @contents = []
      @i = 0
      @headers = []
    end

    def start_element(name, attrs)
      @attrs = attrs
      @content = ''
      @i += 1
    end

    def end_element(name)
      @open_struct.item_brand = @content if name == 'item_brand'
      @open_struct.item_category = @content if name == "item_category"
      @open_struct.department = @content if name == "department"
      @contents << @content
      @headers << name
      if name == "item_data"
        if !@@header_set
          @@main_array << @headers
          @@header_set = true
        end
        if @open_struct.department == "womens" && @open_struct.item_category.to_s.downcase == "apparel" && ["adidas", "biba", "chemistry", "fabindia", "french connection", "lee", "puma", "united colors of benetton", "levis"].include?(@open_struct.item_brand.to_s.downcase)
          @@main_array << @contents
          p @@main_array.count
        end
        @contents = []
      end

      @content = nil
    end

    def characters(string)
      @content << string if @content
    end

    def cdata_block(string)
      characters(string)
    end
  end

  parser = Nokogiri::XML::SAX::Parser.new(MyDocument.new)
  parser.parse(gz)


else
  p "Try Different format - Its not working"
end


#NEEEEEEEEEEEEEEEWWWWWWWWWWWWWWWWWw

# Apparel
url = "https://assoc-datafeeds-eu.amazon.com/datafeed/getFeed?filename=in_amazon_apparel.xml.gz"
# url = "https://assoc-datafeeds-eu.amazon.com/datafeed/getFeed?filename=in_amazon_kindle.xml.gz"
digest_auth = Net::HTTP::DigestAuth.new

uri = URI.parse(url)
uri.user = "pla04"
uri.password = "cyn04"

h = Net::HTTP.new uri.host, uri.port
h.use_ssl = true
h.ssl_version = :TLSv1

req = Net::HTTP::Get.new uri.request_uri

res = h.request req
# res is a 401 response with a WWW-Authenticate header

auth = digest_auth.auth_header uri, res['www-authenticate'], 'GET'

# create a new request with the Authorization header
req = Net::HTTP::Get.new uri.request_uri
req.add_field 'Authorization', auth

# re-issue request with Authorization
res = h.request req

if res.kind_of?(Net::HTTPFound)
  location = res["location"]
  infile = open(location)
  gz = Zlib::GzipReader.new(infile)
  @@main_xml_str = ""

  require 'rubygems'
  require 'nokogiri'

  class MyDocument < Nokogiri::XML::SAX::Document
    def initialize
      @open_struct = OpenStruct.new
      @contents = []
      @each_data_str = ""
      @i = 0
      @headers = []
    end

    def start_element(name, attrs)
      @attrs = attrs
      @content = ''
      @each_data_str << "<#{name}>"
    end

    def end_element(name)
      @each_data_str << "#{CGI.escape_html(@content.to_s)}</#{name}>"
      # p 11111111111111111
      # p "#{name} : #{@content}"
      @open_struct.item_brand = @content if name == 'item_brand'
      @open_struct.item_category = @content if name == "item_category"
      @open_struct.department = @content if name == "department"

      if name == "item_data"
        if @open_struct.department == "womens" && @open_struct.item_category.to_s.downcase == "apparel" && ["adidas", "biba", "chemistry", "fabindia", "french connection", "lee", "puma", "united colors of benetton", "levis"].include?(@open_struct.item_brand.to_s.downcase)
          # @@main_array << @contents
          # p @@main_array.count
          @i += 1
          p @i
          @@main_xml_str << @each_data_str
        end
        @each_data_str = ""
      end

      @content = nil
    end

    def characters(string)
      @content << string if @content
    end

    def cdata_block(string)
      characters(string)
    end
  end

  parser = Nokogiri::XML::SAX::Parser.new(MyDocument.new)
  parser.parse(gz)

  @@main_xml_str = "<DataFeeds>" + @@main_xml_str if !@@main_xml_str.include?("<DataFeeds>")
  @@main_xml_str << "</DataFeeds>"

  filename = "report_#{Time.now.strftime('%d_%b_%Y')}_#{Time.now.to_i}.xml".downcase

  object = $s3_object.objects["reports/#{filename}"]
  object.write(@@main_xml_str)
  # object.write(return_val)
  object.acl = :public_read
  p filename

  # object = $s3_object.object(["reports/#{filename}"])
  # object.write(return_val)
  # object.acl = :public_read
else
  p "Try Different format - Its not working"
end


# Beauty
url = "https://assoc-datafeeds-eu.amazon.com/datafeed/getFeed?filename=in_amazon_beauty.xml.gz"
# url = "https://assoc-datafeeds-eu.amazon.com/datafeed/getFeed?filename=in_amazon_kindle.xml.gz"
digest_auth = Net::HTTP::DigestAuth.new

uri = URI.parse(url)
uri.user = "pla04"
uri.password = "cyn04"

h = Net::HTTP.new uri.host, uri.port
h.use_ssl = true
h.ssl_version = :TLSv1

req = Net::HTTP::Get.new uri.request_uri

res = h.request req
# res is a 401 response with a WWW-Authenticate header

auth = digest_auth.auth_header uri, res['www-authenticate'], 'GET'

# create a new request with the Authorization header
req = Net::HTTP::Get.new uri.request_uri
req.add_field 'Authorization', auth

# re-issue request with Authorization
res = h.request req

if res.kind_of?(Net::HTTPFound)
  location = res["location"]
  infile = open(location)
  gz = Zlib::GzipReader.new(infile)
  @@main_xml_str = ""

  require 'rubygems'
  require 'nokogiri'

  class MyDocument < Nokogiri::XML::SAX::Document
    def initialize
      @open_struct = OpenStruct.new
      @contents = []
      @each_data_str = ""
      @i = 0
      @headers = []
    end

    def start_element(name, attrs)
      @attrs = attrs
      @content = ''
      @each_data_str << "<#{name}>"
    end

    def end_element(name)
      @each_data_str << "#{CGI.escape_html(@content.to_s)}</#{name}>"
      # p 11111111111111111
      # p "#{name} : #{@content}"
      @open_struct.item_brand = @content if name == 'item_brand'
      @open_struct.item_category = @content if name == "item_category"
      @open_struct.department = @content if name == "department"

      if name == "item_data"
        if @open_struct.department == "womens" && @open_struct.item_category.to_s.downcase == "beauty" && ["maybelliene", "l'oreal", "lakme", "urban decay", "colourpop", "tarte", "sephora", "benefit", "bobbi brown", "mac", "estee lauder", "clinique", "forest essentials", "kama"].include?(@open_struct.item_brand.to_s.downcase)
          # @@main_array << @contents
          # p @@main_array.count
          @i += 1
          p @i
          @@main_xml_str << @each_data_str
        end
        @each_data_str = ""
      end

      @content = nil
    end

    def characters(string)
      @content << string if @content
    end

    def cdata_block(string)
      characters(string)
    end
  end

  parser = Nokogiri::XML::SAX::Parser.new(MyDocument.new)
  parser.parse(gz)

  @@main_xml_str = "<DataFeeds>" + @@main_xml_str if !@@main_xml_str.include?("<DataFeeds>")
  @@main_xml_str << "</DataFeeds>"

  filename = "report_beauty_#{Time.now.strftime('%d_%b_%Y')}_#{Time.now.to_i}.xml".downcase

  object = $s3_object.objects["reports/#{filename}"]
  object.write(@@main_xml_str)
  # object.write(return_val)
  object.acl = :public_read
  p filename

  # object = $s3_object.object(["reports/#{filename}"])
  # object.write(return_val)
  # object.acl = :public_read
else
  p "Try Different format - Its not working"
end
