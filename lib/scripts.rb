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