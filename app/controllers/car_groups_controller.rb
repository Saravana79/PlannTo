class CarGroupsController < ProductsController

  def show
    @item = Item.where(:id => params[:id]).includes(:item_attributes).last
  end
end
