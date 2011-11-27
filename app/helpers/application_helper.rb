module ApplicationHelper

  def get_follow_link(name, path, options = {})
    link_to(("<span>"+name+"</span>").html_safe, path, options)
  end


  def get_follow_types(item, follow_type, type, options = {})
    array_follow = get_follow_text(follow_type)
    if type == "select_box"
      select_tag("follow_type", options_for_select(array_follow),
                 {"data-remote" => true, "data-url" => follow_item_type_item_path(item),
                  :id => array_follow.first[1].to_s+"_select"})
    else
      links_follow = ""
      array_follow.each do |text_val, id_val, follow|                
          links_follow += "<span class='productbuttons' id=#{id_val+'_span'}>" +
            get_follow_link(text_val, follow_item_type_item_path(item, :follow_type => follow),
                            options.merge(:id => id_val)) +
          '</span>'
      end
      links_follow.html_safe
    end
  end

  def get_follow_text(follow_type)
    case follow_type
      when 'Manufacturer', 'CarGroup'
        [["Follow This Car", "plan_to_follow", "Follow"]]
      when 'Car'
        [[ "Plan to buy", "plan_to_buy", "Buyer"], ["I Own it", "plan_to_own", "Owner"], ["Follow This Car", "plan_to_follow", "Follow"]]
      else
        [[ "Plan to buy", "plan_to_buy", "Buyer"], ["I Own it", "plan_to_own", "Owner"], ["Follow This Car", "plan_to_follow", "Follow"]]
    end
  end

  def get_image_url(item, type = 'Car')
    case type
      when 'Car'
        configatron.car_image_url + item.imageurl
      when 'Manufacturer', 'CarGroup'
        configatron.mobile_image_url + item.imageurl
    end

  end
end
