module Admin::AdReportsHelper

  def get_ectr(clicks, impressions)
    ((clicks.to_f/impressions.to_f)*100).round(2)
  end

  def get_if_item(id)
    if params[:type] == "Item"
      item = @items.select {|item| item.id == id.to_i}.last
      item.blank? ? id : item.name
    else
      id
    end
  end
end
