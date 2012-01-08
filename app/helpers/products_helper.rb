module ProductsHelper

  def display_item_type(item)
    return "#{item.type.pluralize}"
  end

  def display_item_type_url(item)
    return "/#{item.type.downcase.pluralize}"
  end

  def display_item_manufacturer(item)
    return "#{item.manufacturer.name}"
  end

  def display_item_manufacturer_url(item)
    return ""
  end

  def display_item_group(item)
    if item.type == "Car"
      return "#{item.cargroup.name}"
      #to be changed.
    elsif item.type == "Mobile"
      return "#{item.manufacturer.name}"
    else
      return ""
    end
  end

  def display_item_group_url(item)
    return ""
  end

  def display_item(item)
    return "#{item.name}"
  end

  def display_item_url(item)
    return "/#{item.type.pluralize}/#{item.id}"
  end
end
