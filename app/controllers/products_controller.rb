class ProductsController < ApplicationController
  layout 'product'
  def index

  end

  def specification
    @item = Item.find_by_id(params[:id])
  end

  def show
    @user = User.last
    @item = Item.where(:id => params[:id]).includes(:item_attributes).last
    @user_follow = Follow.all_follower_type(@user, @item).group_by(&:follow_type)
    @user.follow_type = if !@user_follow["Buyer"].blank?
                          "Buyer"
                        elsif !@user_follow["Owner"].blank?
                          "Owner"
                        elsif !@user_follow["Follow"].blank?
                          "Follow"
                        end
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
