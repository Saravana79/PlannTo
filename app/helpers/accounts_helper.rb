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
end
