module SearchHelper

  def image_url(item)
    if item.type == "Mobile"
      return "http://plannto.com/images/mobile/" + item.imageurl
    else
      return "http://plannto.com/images/car/" + item.imageurl
    end
  end

  def link_url(item)
     return "/#{item.type.downcase.pluralize}/#{item.id}"
  end
end
