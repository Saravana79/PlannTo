class NewuserWizardsController < ApplicationController
  before_filter :authenticate_user!
  layout "product"
  
  def new
    @static_page = "true"
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
    @wizard_type = @type == "owner" ? "follower" : "buyer"
    if !params[:invitation_id].blank? 
      @invitation = Invitation.find(params[:invitation_id]) 
      @item = @invitation.item
     end  
    if @type == "owner"
       @item_id = Item.get_owner_item_ids_for_user(current_user,"all").join(",")
       @items = Item.get_topics_follower_ids_for_user(current_user)
    else
      @item_id = Item.get_topics_follower_ids_for_user(current_user,"all").join(",")
      @items = Item.get_buyer_item_ids_for_user(current_user)  
    end 
    session[:wizard] = ''  
  
    #Follow.wizard_save(params[:wizard][:item_id],@type,current_user)
    # current_user.clear_user_follow_item
    if @type == "follower"
      @not_follow = Follow.where('follower_id =? and followable_type in (?) and follow_type=?',current_user.id, Item::TOPIC_FOLLOWTYPES,@type).blank? ? "true" : ""
     else
       @not_follow = Follow.where('follower_id =? and followable_type in (?) and follow_type=?',current_user.id, Item::FOLLOWTYPES,@type).blank? ? "true" : ""
    end   
  end 
  
  def product_select
    @item = Item.find(params[:item_id])
    @wizard_type = params[:type]
    Follow.wizard_save(params[:item_id], @wizard_type,current_user)
      current_user.clear_user_follow_item
      @itemtype = Itemtype.find_by_itemtype(@item.itemtype.itemtype)
      @buying_plan = BuyingPlan.where(:user_id => current_user.id, :itemtype_id => @itemtype.id).first
      if @buying_plan.nil?
        @buying_plan = BuyingPlan.create(:user_id => current_user.id, :itemtype_id => @itemtype.id)
       UserActivity.save_user_activity(current_user,@buying_plan.id,"added","Buying Plan",@buying_plan.id,request.remote_ip)
       @buying_plan.update_attribute(:deleted, false)
       @buying_plan.update_attribute(:completed, false) 
      end  
      @question = @buying_plan.user_question #.destroy
    if @question.nil?
      @question = UserQuestion.new(:title => "Planning to buy a #{@buying_plan.itemtype.itemtype}", :buying_plan_id => @buying_plan.id)
     @question.save
   end
   
  end
  
  def previous
    @previous = params[:previous]
    session[:wizard] = ''
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
    unless current_user.follows.where('followable_id =? and followable_type =? and follow_type =?', @item.id,@item.type,params[:type]).blank?
       current_user.follows.where('followable_id =? and followable_type =? and follow_type =?', @item.id,@item.type,params[:type]).first.destroy
    end
  end
end
