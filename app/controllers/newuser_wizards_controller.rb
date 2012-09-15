class NewuserWizardsController < ApplicationController
  layout "product"
  
  def new
  
  end
  
  def create
    @type = params[:wizard][:type]
    Follow.wizard_save(params[:wizard][:item_id],@type,current_user)
  end 
  
  def product_select
    @item = Item.find(params[:item_id])
  end
  
  def product_delete
    @item = Item.find(params[:id])
  end
end
