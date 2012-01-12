module ProductsHelper

  def display_item_type(item)
    "#{item.type.pluralize}"
  end

  def display_item_type_url(item)
    "/#{item.type.downcase.pluralize}"
  end

  def display_item_manufacturer(item)
    "#{item.name}"
  end

  def display_item_manufacturer_url(item)
    ""
  end

  def display_item_group(item)
    if item.type == "Car"
      "#{item.cargroup.name}"
      #to be changed.
    elsif item.type == "Mobile"
      "#{item.manufacturer.name}"
    else
      ""
    end
  end

  def display_item_group_url(item)
    ""
  end

  def display_item(item)
    "#{item.name}"
  end

  def display_item_url(item)
    "/#{item.type.pluralize}/#{item.id}"
  end
end
