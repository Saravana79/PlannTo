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
  itemdetail = attachment.instance.imageable rescue nil
  if_item_detail = itemdetail.blank? ? "" : itemdetail.class.to_s.downcase rescue ""
  image_type = attachment.instance.imageable.type.downcase rescue "ad"
  table_name = attachment.instance.imageable.class.table_name
  if if_item_detail == "itemdetail"
    vendor_name = itemdetail.get_vendor_name rescue nil
    vendor_name = vendor_name.blank? ? "MySmartPrice" : vendor_name
    return_val = "vendors/#{vendor_name}"    #TODO: hot code value for MySmartPrice
  else
    return_val = "#{table_name}/#{image_type}"
  end
  return_val
end