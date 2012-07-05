module AccountsHelper
  def get_items_with_constraint(follow_item, follow_types, per_page=8)
    page = request.xhr? ? @page :  params["page"]
    car_items = get_array(follow_item, follow_types)
    car_items.paginate(:page => page, :per_page => per_page) rescue [].paginate
  end

  def get_array(follow_array, array_values)
    array_values.collect do |val|
      follow_array[val].blank? ?  [] : follow_array[val]
    end.flatten
  end

  def link_for_item_type(item_type, selected_item, user)
    if item_type == selected_item || (selected_item.nil? && item_type=="Cars")
      content_tag(:li,
        link_to(content_tag(:span, item_type), profile_path(user.try(:username), :follow => item_type)),
      :class => "tab_active")
    else
      content_tag(:li,
        link_to(content_tag(:span, item_type), profile_path(user.try(:username), :follow => item_type)))
    end
  end
end
