module ProductsHelper

  def display_item_type(item)

    if (!item.is_a? CarGroup)
      text = "#{item.type.pluralize}"
    else
      text = "#{item.related_cars.first.type.pluralize}"
    end 
    
    if((item.is_a? Product) || (item.is_a? CarGroup))
      "<a class='alink' href='" + display_item_type_url(@item) + "'>" + text + "</a>"
    else
      "<a id='alink_active' >" + text + "</a>"
    end
     


  end
  
  def display_item_type_url(item)
    if (item.is_a? Product)
      "/#{item.type.downcase.pluralize}"
    else if (item.is_a? CarGroup)
      "/#{item.related_cars.first.type.downcase.pluralize}" 
      end
    end  
  end
  
  def display_item_manufacturer(item)
    "#{item.manu.name}"
  end

  def display_item_manufacturer_url(item)
    "/#{item.manu.type.downcase.pluralize}/#{item.manu.id.to_s}"
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
