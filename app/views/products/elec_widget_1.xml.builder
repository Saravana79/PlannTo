xml.instruct!
xml.results do
  @where_to_buy_items.each do |item_detail|
    xml.item do
      xml.id item_detail.itemid
      xml.provider @vendor_ad_details[item_detail.site.to_i]['vendor_name']
      xml.productName item_detail.ItemName
      xml.URL item_detail.url
      xml.price display_price_detail(item_detail)
      xml.MRP prettify_mrpprice_widget(item_detail.mrpprice)
      xml.status item_detail.status
      xml.match item_detail.match_type
    end
  end
end