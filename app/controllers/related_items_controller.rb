class RelatedItemsController < ApplicationController
  layout "product"
  
  def index
  	@item = Item.find(params[:car_id])
    related_item_ids = RelatedItem.where(:item_id => params[:car_id]).order("variance desc").collect(&:related_item_id) #.order("RAND()").limit(3)
    # @related_items = Item.where(:id => related_item_ids,:itemtype_id => item.itemtype.id).includes(:item_rating,:attribute_values).order("id desc").paginate(:page => params[:page], :per_page => 10)
    #@related_items = Item.find(related_item_ids, :order => "field(id, #{related_item_ids.map(&:inspect).join(',')})")

    @related_items = Item.where(:id => related_item_ids)
    @related_items = related_item_ids.collect {|id| @related_items.detect {|x| x.id == id}}
    @related_items.compact!

    @related_items = @related_items.select {|each_item| each_item.itemtype_id == @item.itemtype_id}
    if params[:popup] == "true"
      @related_items = @related_items.first(20)
      # @related_items = Item.last(20)
      return render :partial => "related_items_list", :layout => false
    else
      @related_items = @related_items.paginate(:page => params[:page], :per_page => 10)
    end

  end
end
