class Admin::BuyingPlansController < ApplicationController
  layout "product"
  before_filter :authenticate_admin_user!
  
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
    p = Proposal.new
    p.item_id = params[:proposal_item_id]
    p.buying_plan_id = params[:buying_plan_id]
    p.expiry_date = params[:proposal][:expiry_date]
    p.item_price = params[:proposal][:item_price]
    p.delivery_period = params[:proposal][:delivery_period]
    p.shipping_cost = params[:proposal][:shipping_cost]
    p.color = params[:proposal][:color]
    p.comments =  params[:proposal][:comments]
    p.save
  end
end
