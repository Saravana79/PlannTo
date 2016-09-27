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
    item.manu.get_url()
  end

  def display_item_group(item)
      item.cargroup.name
    end

  def display_item_group_url(item)
    item.cargroup.get_url()
  end

  def display_item(item)
    "#{item.name}"
  end

  def display_item_url(item)
    item.get_url()
  end

    def get_content_based_on_size(params_word,count)
    if (params_word.length > count)
      params_word[0..(count-3)] + "..."
    else
      params_word
    end
    end

  def get_general_click_url(url)
    url = get_update_with_tag_and_ascsubtag(url)
    url = URI.escape(url)

    click_url = configatron.hostname + history_details_path(:ads_id => nil, :iid => @impression_id, :red_sports_url => url, :item_id => @category_item_detail_id, :ref_url => params[:ref_url])
  end

  def get_update_with_tag_and_ascsubtag(url)
    url = get_url_with_key("tag", params[:tag], url)
    url = get_url_with_key("ascsubtag", params[:ascsubtag], url)
    url
  end

  def get_url_with_key(key_name, key_val, url)
    # if !key_val.blank?
      new_tag_val = key_val.to_s
      url = URI.unescape(url)
      if url.include?(key_name)
        tag_val = FeedUrl.get_value_from_pattern(url, "#{key_name}=<tag_val>&", "<tag_val>")

        if tag_val.blank?
          # url = URI.unescape(url)
          tag_val = FeedUrl.get_value_from_pattern(url, "#{key_name}=<tag_val>&", "<tag_val>")
          if tag_val.blank?
            begin
              red_u = URI.parse(url)
              red_p = CGI.parse(red_u.query)
            rescue Exception => e
              red_p = CGI.parse(url)
            end
            if red_p.keys.last == "#{key_name}"
              tag_val = FeedUrl.get_value_from_pattern(url, "#{key_name}=<tag_val>", "<tag_val>")
            end
          end
        end

        url = url.gsub("#{key_name}=#{tag_val}", "#{key_name}=#{new_tag_val}")
        # url = url.gsub(tag_val, "#{publisher_vendor.trackid}") if tag_val == "INSERT_TAG_HERE"
      else
        if url.include?("?")
          url = url + "&#{key_name}=#{new_tag_val}"
        else
          url = url + "?#{key_name}=#{new_tag_val}"
        end
      end
    # end
    url
  end

  def get_expire_time_from_deal_item(each_item)
    if each_item.end_time.to_date == Date.today
      remaining_time = each_item.end_time.hour - Time.now.hour
      if (remaining_time > 8)
        return_val = " Expires Today."
      else
        return_val = " Expires in #{remaining_time} hours."
      end
    else
      return_val = "Expires Soon."
    end
    return_val
  end
end
