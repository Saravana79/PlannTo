class Admin::BuyingPlansController < ApplicationController
  layout "product"
  before_filter :authenticate_admin_user! ,:only =>[:index]
  before_filter :authenticate_user!,:only =>[:view_proposal]
  before_filter :authenticate_vendor_user!,:except => [:index,:view_proposal]
  def index
     @buying_plans = BuyingPlan.order('created_at desc').paginate(:per_page => 20,:page => params[:page])
     @admin = "true"
  end 
  
  def search
    @item = Item.find(params[:product_id]) rescue ''
    @item_type_id = @item.itemtype.id rescue ''
    if ((@item.type   == "Manufacturer") || (@item.type == "CarGroup") rescue false)
      @item_type_id = Itemtype.find_by_itemtype("Car").id
      item_ids = @item.related_cars.collect(&:id)
      @buyers = Follow.where('follow_type= ? and followable_id in (?)','buyer',item_ids) rescue ''
    else 
   
       @buyers = Follow.where('follow_type= ? and followable_id =?','buyer',params[:product_id]) rescue ''
     end  
  end
  
  def proposal
    @item = Item.find(params[:item_id])
    @buying_plan = BuyingPlan.find(params[:buying_plan_id])
  end
  
  def proposal_save
    vendor_id = UserRelationship.where(:user_id => current_user.id,:relationship_type => "Vendor").first.relationship_id
    p = Proposal.new
    p.item_id = params[:proposal_item_id]
    p.user_id = current_user.id
    p.vendor_id = vendor_id
    p.buying_plan_id = params[:buying_plan_id]
    p.expiry_date = params[:proposal][:expiry_date]
    p.item_price = params[:proposal][:item_price]
    p.delivery_period = params[:proposal][:delivery_period]
    p.shipping_cost = params[:proposal][:shipping_cost]
    p.color = params[:proposal][:color]
    p.comment =  params[:proposal][:comment]
    p.save
  end
  
  def update
    p = Proposal.find(params[:proposal_id])
    p.item_id = params[:proposal_item_id]
    p.expiry_date = params[:proposal][:expiry_date]
    p.item_price = params[:proposal][:item_price]
    p.delivery_period = params[:proposal][:delivery_period]
    p.shipping_cost = params[:proposal][:shipping_cost]
    p.color = params[:proposal][:color]
    p.comment =  params[:proposal][:comment]
    p.save
  end
  
  def proposal_edit
    @proposal = Proposal.find(params[:id])
    @buying_plan = @proposal.buying_plan
    @item = @proposal.item
  end
  
  def proposal_list
    @proposals = Proposal.where(:user_id => current_user.id)
  end
  
 def view_proposal
   @proposal = Proposal.find(params[:id])
   if  @proposal.user_id != current_user.id  || @proposal.buying_plan.user_id!= current_user.id
    redirect_to root_path
   end
   @edit = params[:edit]
   if params[:edit] == "true" && @proposal.user_id != current_user.id 
     redirect_to root_path
    end
 end 
end
