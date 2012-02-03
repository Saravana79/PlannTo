module ProductsHelper

  def display_item_type(item)
    "#{item.type.pluralize}"
  end
  
  def display_item_type_url(item)
    "/#{item.type.downcase.pluralize}"
  end

  def display_item_manufacturer(item)
    "#{item.manufacturer.name}"
  end

  def display_item_manufacturer_url(item)
    "/#{item.manufacturer.type.downcase.pluralize}/#{item.manufacturer.id.to_s}"
  end

  def display_item_group(item)
      item.cargroup.name
    end

  def display_item_group_url(item)
    "/car_groups/#{item.cargroup.id.to_s}"
  end

  def display_item(item)
    "#{item.name}"
  end

  def display_item_url(item)
    "/#{item.type.pluralize}/#{item.id}"
  end
end
