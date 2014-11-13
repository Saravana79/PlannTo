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
  if_item_detail = attachment.instance.imageable.class.to_s.downcase rescue ""
  image_type = attachment.instance.imageable.type.downcase rescue "ad"
  table_name = attachment.instance.imageable.class.table_name
  if if_item_detail == "itemdetail"
    return_val = "vendors/MySmartPrice"    #TODO: hot code value for MySmartPrice
  else
    return_val = "#{table_name}/#{image_type}"
  end
  return_val
end