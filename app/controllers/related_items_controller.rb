class RelatedItemsController < ApplicationController
  layout "product"
  
  def index
  	item = Item.find(params[:car_id])
    related_item_ids = RelatedItem.where(:item_id => params[:car_id]).order("variance desc").collect(&:related_item_id) #.order("RAND()").limit(3)
    # @related_items = Item.where(:id => related_item_ids,:itemtype_id => item.itemtype.id).includes(:item_rating,:attribute_values).order("id desc").paginate(:page => params[:page], :per_page => 10)
    @related_items = Item.find(related_item_ids, :order => "field(id, #{related_item_ids.map(&:inspect).join(',')})")
    @related_items = @related_items.select {|each_item| each_item.itemtype_id == item.itemtype_id}
    @related_items = @related_items.paginate(:page => params[:page], :per_page => 10)
  end
end
