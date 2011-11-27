module ApplicationHelper

  def get_follow_link(name, path, options = {})
    link_to(("<span>"+name+"</span>").html_safe, path, options)
  end


  def get_follow_types(item, array_follow, type, options = {})
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
end
