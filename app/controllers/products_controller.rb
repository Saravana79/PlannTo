class ProductsController < ApplicationController
  
  layout 'product'
  
  def index

  end

  def specification
    @item = Item.find_by_id(params[:id])
  end

  def show
#    build_resource(:car)
    @user = User.first
    @item = Item.where(:id => params[:id]).includes(:item_attributes).last
    @user_follow = @user.get_follow(@item)    
    @user.follow_type = @user_follow.follow_type
  end

  def related_products
    @item = Item.where(:id => params[:id]).last
    @user = User.last
    @user.follow_type = params[:follow_type]
    respond_to do |format|
      format.js { render :partial=> 'itemrelationships/relateditem', :collection => @item.unfollowing_related_items(@user) }
    end

  end
end
