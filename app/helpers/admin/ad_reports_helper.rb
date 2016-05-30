module Admin::AdReportsHelper

  def get_ectr(clicks, impressions)
    return_val = ((clicks.to_f/impressions.to_f)*100).round(2)
    return_val = return_val.inspect == "NaN" ? 0.0 : return_val
  end

  def get_if_item(id)
    if params[:type] == "Item"
      get_item(id)
    else
      if params[:type] == "Domain"
        id.to_s.gsub("^", ".")
      else
        id
      end
    end
  end

  def get_item(item_id)
    item = @items.select {|item| item.id == item_id.to_i}.last
    item.blank? ? item_id : item.name
  end
end
