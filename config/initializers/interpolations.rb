Paperclip.interpolates(:imgeable_type) do |attachment, style|
  attachment.instance.imageable.type.downcase rescue "ad"
end

Paperclip.interpolates(:img_table_name) do |attachment, style|
  attachment.instance.imageable.class.table_name
end