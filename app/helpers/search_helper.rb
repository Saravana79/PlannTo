module SearchHelper

  def image_url(item)  
    if item.type == "Mobile"
      return configatron.mobile_image_url + item.imageurl
    elsif item.type == "Car"
      return configatron.car_image_url + item.imageurl
    elsif item.type == "Tablet"
      return configatron.tablet_image_url + item.imageurl
    elsif item.type == "Camera"
      return configatron.camera_image_url + item.imageurl
    else
      return ""
    end
  end

  def link_url(item)
     return item.get_url()
  end

  def view_all_related_items_url(item)
    return "/#{item.type.downcase}/related-items/#{item.id}"
  end

end
