module AccountsHelper
  def get_items_with_constraint(follow_item, follow_types)
    require 'will_paginate/array'
     car_items = get_array(follow_item, follow_types)
     return car_items
  end

  def get_array(follow_array, array_values)
  logger.info array_values
    array_values.collect do |val|
    logger.info val
      follow_array[val].blank? ?  [] : follow_array[val]
    end.flatten
  end

  def link_for_item_type(item_type, selected_item, user)
    if item_type == selected_item || (selected_item.nil? && item_type=="Products
    ") || ( selected_item.include?("Preferences")  && item_type.include?("Preferences"))
       if selected_item == "Preferences" && item_type.include?("Preferences")
       
        return content_tag(:li,link_to(content_tag(:span,"Preferences / Buying Plans"), profile_path(user.try(:username), :follow => "Preferences")),
      :class => "tab_active")
      end
      content_tag(:li,
        link_to(content_tag(:span, item_type), profile_path(user.try(:username), :follow => item_type)),
      :class => "tab_active")
     
    else
     if item_type.include?("Preferences")
   
      return content_tag(:li,link_to(content_tag(:span,"Preferences / Buying Plans"), profile_path(user.try(:username), :follow => "Preferences")))
      end     
      content_tag(:li,
        link_to(content_tag(:span, item_type), profile_path(user.try(:username), :follow => item_type)))
    end
  end
end
