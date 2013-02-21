class Admin::BuyingPlansController < ApplicationController
  layout "product"
  before_filter :authenticate_admin_user!
  
  def index
     @buying_plans = BuyingPlan.order('created_at desc').paginate(:per_page => 20,:page => params[:page])
     @admin = "true"
  end     
end
