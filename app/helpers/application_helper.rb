module ApplicationHelper
# require 'global_utilities'
  def get_follow_link(name, path, options = {})
    link_to(name, path, options).to_s
  end

  def date_formate(d)
    day = d.day  rescue ''
    if day == ''
     return ''
    end
    month = d.month.to_i - 1
    year = d.year
    months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec','']
    month = months[month]
    return "#{day}-#{month}-#{year}"
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
          if (follow_type == 'Car' || follow_type == 'Bike' || follow_type == 'Cycle' || follow_type == 'Mobile' || follow_type == 'Tablet' || follow_type == 'Camera') && !options[:related_items] && button_class ==''
            '</span><span class="plantobuycounter">' + item.ger_followers_count_for_type(follow).to_s + '</span>'
         else
          '</span>'
         end
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

  def show_comparision_summary(attr_ca, items)
    order = attr_ca.order
    compare = items.collect(&:attribute_values).flatten.collect{|av| av if items.collect(&:id).include?(av.item_id) && av.attribute_id==attr_ca.attribute_id}.compact.flatten.uniq.group_by(&:groupbyvalue)

    # compare = attr_ca.a.attribute_values.collect{|av| av if items.collect(&:id).include?(av.item_id)}.compact.flatten.group_by(&:groupbyvalue)
    topitems = Hash.new
    compare.each do |key, value|
      compare[key] = value.collect{|av| items.select{|i| i if i.id==av.item_id}.flatten.compact.uniq.first.name}.flatten.compact.uniq
      topitems[key] = value.collect{|av| av.item_id}
    end

    if(["asc", "desc"].include?(order[:value]))
        compare = compare.select{|key| true if Float(key) rescue false}
        attr_v = compare.keys.sort_by{|key| key.to_f}
        if(["desc"].include?(order[:value]))
          attr_v = attr_v.reverse
        end
    else
        attr_v = compare.keys.sort
    end

    if attr_v.size > 1 and ["asc", "desc"].include?(order[:value])
        percentage = get_percentage(order, attr_v)

        attr_ca.description.gsub!("{2}", compare[attr_v[1]].to_sentence)
        attr_ca.description.gsub!("{percentage}", percentage) if attr_ca.description.match("{percentage}")
        attr_ca.description.gsub!("{1}", compare[attr_v[0]].to_sentence)

        {summary: attr_ca.description, highlight: topitems[attr_v[0]],winner:compare[attr_v[0]].to_sentence}

    elsif (attr_v.size > 0 and "eq".include?(order[:value]))
       matchkey = -1
       index = 0
       attr_v.each do |key|
          if("eq".include?(order[:value]) and attr_v[index].to_s.downcase == attr_ca.value.downcase)
              matchkey = index
          end
          index =  index + 1
       end
       if(matchkey > 0 and compare[attr_v[matchkey]].size < items.size )
        attr_ca.description.gsub!("{1}", compare[attr_v[matchkey]].to_sentence)
        {summary: attr_ca.description, highlight: topitems[attr_v[matchkey]],winner:compare[attr_v[matchkey]].to_sentence}
       end
    elsif (attr_v.size > 0 and "con".include?(order[:value]))
       itemArry = Array.new
       valueArry = Array.new
       attr_v.each do |key|
         if (key.to_s.downcase.include? attr_ca.value.downcase)
            itemArry = itemArry +  compare[key]
            valueArry = valueArry + topitems[key]
         end
       end
       if(itemArry.length > 0)
        attr_ca.description.gsub!("{1}", itemArry.to_sentence)
        {summary: attr_ca.description, highlight: valueArry,winner:itemArry.to_sentence}
       end
    else
      nil
    end

  end

  def get_percentage(order, attr_v)
    if order[:value] == "asc"
      "#{(((attr_v[1].to_f - attr_v[0].to_f)/attr_v[0].to_f)*100).round}%"  rescue '0%'
    else
      "#{(((attr_v[0].to_f - attr_v[1].to_f)/attr_v[1].to_f)*100).round}%"  rescue '0%'
    end
  end

  def truncate_without_dot(str, size)
    # result_str = truncated_str.gsub(/\s(\S*\.)$/, '')

    skip_values = ["rs.","2."]
    result_str = str.to_s.strip
    if result_str.length > size
      truncated_str = result_str.to_s[0...size]
      if truncated_str.include?(".")
        splitted_str_by_dot = truncated_str.split(/\.[^\\.]*$/)
        result_str = splitted_str_by_dot[0] + "."
        result_str = truncated_str if (skip_values.include?(result_str.last(3).downcase) || skip_values.include?(result_str.last(2).downcase))
      elsif truncated_str.include?(",")
        splitted_str_by_comma = truncated_str.split(/\,[^\\,]*$/)
        result_str = splitted_str_by_comma[0].strip
      elsif truncated_str.include?("+")
        splitted_str_by_plus = truncated_str.split(/\+[^\\+]*$/)
        result_str = splitted_str_by_plus[0].strip
      else
        result_str = ""
      end
    end

    return result_str.strip
  end

  def prettify(item_detail)
    pre_order_val = item_detail.status == 3 ? "Pre-Order" : ""
    if(!item_detail.cashback.nil? && item_detail.cashback != 0.0)
      price = item_detail.price == 0.0 ? pre_order_val :  number_to_indian_currency("%.2f" %(item_detail.price.to_f - item_detail.cashback.to_f))
    else
      price = item_detail.price == 0.0 ? pre_order_val :  number_to_indian_currency("%.2f" % item_detail.price.to_f)
    end
  end

  def prettify_mrpprice(item_detail)
    pre_order_val = item_detail.status == 3 ? "Pre-Order" : ""

    if pre_order_val == ""
      price = item_detail.mrpprice.blank? ? "" : number_to_indian_currency("%.2f" % item_detail.mrpprice.to_f)
    else
      price = ""
    end

    price
  end

   def prettifyforcarprice(item_detail)
      price = item_detail.price == 0.0 ? pre_order_val :  number_to_indian_currency("%.0f" % item_detail.price.to_f)
   end

   def prettifyforcaremi(item_detail)
      price = item_detail.price == 0.0 ? pre_order_val :  number_to_indian_currency("%.0f" % item_detail.cashback.to_f)
   end

end