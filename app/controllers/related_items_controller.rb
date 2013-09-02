class RelatedItemsController < ApplicationController
  layout "product"
  
  def index
  	item = Item.find(params[:car_id])
    related_item_ids = RelatedItem.where(:item_id => params[:car_id]).collect(&:related_item_id) #.order("RAND()").limit(3)
    @related_items = Item.where(:id => related_item_ids,:itemtype_id => item.itemtype.id).includes(:item_rating,:attribute_values).order("id desc").paginate(:page => params[:page], :per_page => 10)
  end
end
