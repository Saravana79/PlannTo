module AccountsHelper
  def get_items_with_constraint(follow_item, follow_types)
    car_items = get_array(follow_item, follow_types)
    car_items.paginate(:page => params["page"], :per_page => 8) rescue [].paginate
  end

  def get_array(follow_array, array_values)
    array_values.collect do |val|
      follow_array[val].blank? ?  [] : follow_array[val]
    end.flatten
  end
end
