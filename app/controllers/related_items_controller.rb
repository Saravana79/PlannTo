class RelatedItemsController < ApplicationController
  layout "product"
  
  def index
    related_item_ids = RelatedItem.where(:item_id => params[:car_id]).collect(&:related_item_id) #.order("RAND()").limit(3)
    @related_items = Item.where(:id => related_item_ids).paginate(:page => params[:page], :per_page => 5)
  end
end
