class NewuserWizardsController < ApplicationController
  before_filter :authenticate_user!
  layout "product"
  
  def new
  
   if !params[:invitation].blank? 
     @invitation = Invitation.find(params[:invitation]) 
      @item = @invitation.item
      @wizard_type = "owner"
    
      if @invitation.email != current_user.email && @invitation.token.blank?
        redirect_to "/"
       end  
    end   
  end
  
  def create
    @type = params[:wizard][:type]
    if !params[:invitation_id].blank? 
      @invitation = Invitation.find(params[:invitation_id]) 
      @item = @invitation.item
      @wizard_type = @type == "owner" ? "follower" : "buyer"
    end  
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
