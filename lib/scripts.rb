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


## Item loads from mysmartprice

require 'xmlsimple'

url = "http://www.mysmartprice.com/store_data/msp_master.xml"
xml_data = Net::HTTP.get_response(URI.parse(url)).body
data = XmlSimple.xml_in(xml_data)
items = data["channel"][0]["item"]

items.each do |item|
  title = item["title"][0]
  product_type = item["product_type"][0].to_s.split(">")[1].to_s.strip
  url = item["link"][0]

  itemtype_hash = {"mobile" => 6, "laptops" => 23, "tablet" => 13}

  source_item = Sourceitem.find_or_initialize_by_url(url)
  source_item.update_attributes(:name => title, :status => 1, :urlsource => "Mysmartprice", :itemtype_id => itemtype_hash[product_type], :created_by => "System", :verified => false)
end