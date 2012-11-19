class NewuserWizardsController < ApplicationController
  before_filter :authenticate_user!
  layout "product"
  
  def new
    @items = Item.get_owner_item_ids_for_user(current_user) 
    @wizard_type = "owner"
   if !params[:invitation].blank? 
     @invitation = Invitation.find(params[:invitation]) 
      @item = @invitation.item
      
    
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
    if @type == "owner"
       @items = Item.get_topics_follower_ids_for_user(current_user)
    else
      @items = Item.get_buyer_item_ids_for_user(current_user)  
    end   
    @item_id = params[:wizard][:item_id]
    Follow.wizard_save(params[:wizard][:item_id],@type,current_user)
     current_user.clear_user_follow_item
    if @type == "follower"
      @not_follow = Follow.where('follower_id =? and followable_type in (?) and follow_type=?',current_user.id, Item::TOPIC_FOLLOWTYPES,@type).blank? ? "true" : ""
     else
       @not_follow = Follow.where('follower_id =? and followable_type in (?) and follow_type=?',current_user.id, Item::FOLLOWTYPES,@type).blank? ? "true" : ""
    end   
  end 
  
  def product_select
    @item = Item.find(params[:item_id])
  end
  
  def previous
    @previous = params[:previous]
    case @previous
      when "owner" 
        @wizard_type = "owner"
        @items = Item.get_owner_item_ids_for_user(current_user) 
      when "follower"
        @wizard_type = "follower"
        @items = Item.get_topics_follower_ids_for_user(current_user)
     end
  end
      
  def product_delete
    @item = Item.find(params[:id])
    unless current_user.follows.where('followable_id =? and followable_type !=? and follow_type =?', @item.id,"User",params[:type]).blank?
       current_user.follows.where('followable_id =? and followable_type !=? and follow_type =?', @item.id,"User",params[:type]).first.destroy
    end
  end
end
