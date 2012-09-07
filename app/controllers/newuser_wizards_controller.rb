class NewuserWizardsController < ApplicationController
  layout "product"
  
  def new
  
  end
  
  def create
    @type = params[:wizard][:type]
    Follow.wizard_save(params[:wizard][:item_id],@type,current_user)
  end 
end
