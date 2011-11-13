class ProductsController < ApplicationController
  before_filter :user_follow_item, :if => Proc.new { |c| !current_user.blank? }

  layout 'product'
  
  def index

  end

  def specification
    @item = Item.find_by_id(params[:id])
  end

  def show
    @item = Item.where(:id => params[:id]).includes(:item_attributes).last
    @user_follow = current_user.blank? ? false : user_follow_item[@item.id].last
  end

  def related_products
    @item = Item.where(:id => params[:id]).last
    @follow_type = params[:follow_type]
    respond_to do |format|
      format.js { render :partial=> 'itemrelationships/relateditem', :collection => @item.unfollowing_related_items(current_user, 2) }
    end

  end
end
