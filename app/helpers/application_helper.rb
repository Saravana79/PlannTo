module ApplicationHelper

  def get_follow_link(name, path, options = {})
      link_to(name, path, options).to_s
  end


  def get_follow_types(item, follow_type, type, button_class = '_medium', options = {})
    array_follow = get_follow_text(follow_type)
    if type == "select_box"
      select_tag("follow_type", options_for_select(array_follow),
        {"data-remote" => true, "data-url" => follow_item_type_item_path(item),
          :id => array_follow.first[1].to_s+"_select"})
    else
      links_follow = ""
      array_follow.each do |text_val, id_val, follow|
        text_val = "" if button_class == "_small"
        links_follow += "<span class='action_btns#{button_class}' id=#{id_val+'_span_'+item.id.to_s} title = '#{I18n.t id_val}'>" +
          get_follow_link(text_val, follow_item_type_item_path(item, :follow_type => follow),
          options.merge(:id => id_val+'_'+item.id.to_s, :class => id_val+'_icon'+button_class)) +
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


  def get_the_follow_text(follow_type)
    case follow_type
    when 'Buyer'
      "Plan to buy"
    when 'Owner'
      "I Own it"
    when 'Follow'
      "Follow This Car"
    end
  end

  def get_follow_count(follower_count, follow_type)
    followers = follower_count.select {|fo| fo.follow_type == follow_type}.last
    followers.blank? ? 0 : followers.follow_count
  end

  def get_owners(item)
    Follow.for_followable(item).map(&:follower).map(&:name)
  end

  def get_item_link(item)
    item.class.name.downcase+"_path(item.id)"
  end

  def navigation_sub_menu(active_menu)
    menu = active_menu.nil? ? "" : active_menu.pluralize.capitalize
    #temporary solution
    active_menu = case menu
    when 'Cars'
      "Cars"
    when 'Mobiles'
      "Mobile"
    when 'Cameras'
      "Camera"
    when 'Travels'
      "Travel"
    when 'Movies'
      "Movie"
    when 'Tablets'
      "Tablet"
    else
      ""
    end
    links = ["Cars", "Mobile", "Camera", "Travel", "Movies","Tablet"]
    items = ""
    links.each do |link|
      items+= "<a #{ "id= 'menu_active'" if active_menu == link}"
      items+= " href='/#{link.singularize.downcase}/search'>#{link}</a>"
    end
    return items
  end

  def default_search_type(search_type)
    return "" if (search_type == " " || search_type.nil?)
    return search_type.camelize.constantize
  end
  
  def errors_for(object, message=nil)
    html=""
    object.errors.full_messages.each do |msg| 
      html ="<li>#{msg}</li>"
    end
    html
  end

  def display_item_type(item)
    return item.type.pluralize.capitalize
  end

  def follow_types_classes(follow_type)
     case follow_type
    when 'Buyer'
      "bg_planetobuy"
    when 'Owner'
      "bg_iwonit"
    when 'Follow'
      "bg_following"
    end
  end
end
