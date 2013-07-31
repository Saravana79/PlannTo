class Admin::BuyingPlansController < ApplicationController
  layout "product"
  before_filter :authenticate_admin_user!
  
  def index
     @buying_plans = BuyingPlan.order('created_at desc').paginate(:per_page => 20,:page => params[:page])
     @admin = "true"
  end 
  
  def search
    @item = Item.find(params[:product][:product_id]) rescue ''
    @item_type_id = @item.itemtype.id rescue ''
    @buyers = Follow.where('follow_type= ? and followable_id =?','buyer',params[:product][:product_id]) rescue ''
  end  
end
