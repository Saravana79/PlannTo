# Paperclip.interpolates(:imgeable_type) do |attachment, style|
#   attachment.instance.imageable.type.downcase rescue "ad"
# end
#
# Paperclip.interpolates(:img_table_name) do |attachment, style|
#   table_name = attachment.instance.imageable.class.table_name
#   if table_name == "vendor"
#     table_name
#   end
# end

Paperclip.interpolates(:image_prefix_path) do |attachment, style|
  image_obj = attachment.instance
  imageable_class = image_obj.imageable_type.to_s
  if (imageable_class == "Itemdetail" || imageable_class == "ItemBeautyDetail")
    vendor_name = image_obj.imageable.get_vendor_name rescue nil
    vendor_name = vendor_name.blank? ? "MySmartPrice" : vendor_name
    return_val = "vendors/#{vendor_name}"    #TODO: hot code value for MySmartPrice
  elsif imageable_class == "ItemDetailOther"
    return_val = "item_detail_others/ad"
  elsif imageable_class == "Advertisement"
    return_val = "advertisements/images/:id"
  elsif imageable_class == "Item"
    image_type = image_obj.imageable.type.downcase rescue "item"
    return_val = "items/#{image_type}"
  else
    table_name = image_obj.imageable.class.table_name
    image_type = image_obj.imageable.type.downcase rescue "item"
    return_val = "#{table_name}/#{image_type}"
  end
  return_val
end