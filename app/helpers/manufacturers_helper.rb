module ManufacturersHelper
  def get_price_range(item_group_obj)
    item = Item.get_price_range(item_group_obj.relateditems.map(&:id)).last
    if item
      item.name + ' - ' + item.measure_type + ' ' +
        item.min_value.to_s + '-' + item.max_value.to_s + ' ( ' + item.comment + ' )'
    else
      ""
    end
  end
end
