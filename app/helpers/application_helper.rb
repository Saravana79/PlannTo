module ApplicationHelper
# require 'global_utilities'
  def get_follow_link(name, path, options = {})
    link_to(name, path, options).to_s
  end
   def link_to_add_fields(name, f, association, path=nil)  
   # association = ':' + association
    new_object = f.object.class.reflect_on_association(association).klass.new  
    
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|  
      unless path
        render(association.to_s.singularize + "_fields", :ff => builder)  
      else
        render(path + association.to_s.singularize + "_fields", :ff => builder) 
      end
    end  
     link_to_function(name, "add_fields(this, '#{association}', '#{escape_javascript(fields)}')")
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
        title_value = !options[:related_items] ? (I18n.t item.class.superclass.to_s+'.'+id_val) : " "

        # classname = item.class.superclass.to_s.downcase.pluralize
        classname = "products"
        if(item.is_a?Content)
          classname = "contents"
        end
        links_follow += "<span class='action_btns#{button_class}' id=#{id_val+'_span_'+item.id.to_s}>" +
          get_follow_link(text_val, url_for(:action => 'follow_item_type', :controller => classname, :id => item, :button_class => button_class, :follow_type => follow, :related_items => options[:related_items]),
          options.merge(:id => id_val+'_'+item.id.to_s, :class => id_val+'_icon'+button_class, :title => title_value)) +
          '</span>'
      end
      links_follow.html_safe
    end
  end

  def get_follow_text(follow_type)
    case follow_type
    when 'Manufacturer', 'CarGroup'
      [["Follow This", "plan_to_follow", "follower"]]
    when 'Car','Cycle','Bike','Tablet','Mobile','Camera'
      [[ "Plan to buy", "plan_to_buy", "buyer"], ["I Own it", "plan_to_own", "owner"], ["Follow This", "plan_to_follow", "follower"]]
    when 'Event'
      [[ "May Go", "plan_to_buy", "buyer"], ["Am Going", "plan_to_own", "owner"], ["Follow This", "plan_to_follow", "follower"]]
    when 'Accessories'
      [[ "Plan to buy", "plan_to_buy", "buyer"], ["I Own it", "plan_to_own", "owner"], ["Follow This", "plan_to_follow", "follower"]]
    when 'Apps'
      [["I have it", "plan_to_own", "owner"], ["Follow This", "plan_to_follow", "follower"]]
    when 'Books'
      [[ "PlannTo read", "plan_to_buy", "buyer"], ["I read it", "plan_to_own", "owner"], ["Follow This", "plan_to_follow", "follower"]]
    else
      [["Follow This", "plan_to_follow", "follower"]]
    end
  end


  def get_the_follow_text(follow_type)
    case follow_type
    when 'buyer'
      "Plan to buy"
    when 'owner'
      "Own it"
    when 'follower'
      "Following"
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
    when 'Bikes'
      "Bike"
    when 'Cycles'
      "Cycle"
    when 'Mobiles'
      "Mobile"
    when 'Tablets'
      "Tablet"
    when 'Cameras'
      "Camera"
    else
      ""
    end
    links = ["Cars", "Bikes", "Cycles", "Mobiles", "Tablets","Cameras"]
    items = ""
    links.each do |link|
      items+= "<a #{ "id= 'menu_active'" if active_menu == link}"
      items+= " href='/#{link.singularize.downcase}/search'>#{link}</a>"
    end
    return items
  end

  def default_search_type(search_type)
    return "" if (search_type == " " || search_type.nil?)
    return search_type.singularize.camelize.constantize
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
    when 'buyer'
      "bg_planetobuy"
    when 'owner'
      "bg_iwonit"
    when 'follower'
      "bg_following"
    end
  end

   def get_class_name(class_name)
    parent_class_name = case class_name
    when "Tip" then "Content"
    when "VideoContent" then "Content"
    when "QuestionContent" then "Content"
    when "ReviewContent" then "Content"
    when "ArticleContent" then "Content"
    else class_name
    end
    return parent_class_name
  end

  def get_voting_class_name(user, item)
    keyword_id = "votes_#{user.id}_list"
    vote_list = $redis.smembers "#{keyword_id}"
    class_type = get_class_name(item.class.name)
    value = vote_list.find {|s| s.to_s == "type_#{class_type}_voteableid_#{item.id}".to_s}
    reset = true
    unless value.nil?
      if  user.voted_positive?(item)
        negative_class = "btn_dislike_positive"
        positive_class = "btn_like_positive"
        reset = false
      end
      if user.voted_negative?(item)
        positive_class = "btn_like_negative"
        negative_class = "btn_dislike_negative"
        reset = false
      end
    end
    if reset == true
      positive_class = "btn_like_default"
      negative_class = "btn_dislike_default"    
    end
    return {:positive => positive_class, :negative => negative_class}
  end

  def get_contributor_info(user_id)
    user = User.where("id = ?", user_id).includes(:avatar).first
    return user
  end

  def get_tag_list(item)
    return "<li id='textTaggers#{item.id}' class='taggingmain'><span><a class='txt_tagging' href='#{item.get_url()}' >#{item.name}</a><a id= 'deleteTag' class='icon_close_tagging' href='#'></a></span></li>".html_safe
  end
 
end
