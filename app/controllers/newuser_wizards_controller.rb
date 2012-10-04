class NewuserWizardsController < ApplicationController
  before_filter :authenticate_user!
  layout "product"
  
  def new
  
  end
  
  def create
    @type = params[:wizard][:type]
    @item_id = params[:wizard][:item_id]
    Follow.wizard_save(params[:wizard][:item_id],@type,current_user)
  end 
  
  def product_select
    @item = Item.find(params[:item_id])
  end
  
  def product_delete
    @item = Item.find(params[:id])
  end
end
