class ProductsController < ApplicationController
  before_filter :all_user_follow_item, :if => Proc.new { |c| !current_user.blank? }

  layout 'product'
  
  def index

  end

  def specification
    @item = Item.find_by_id(params[:id])
  end

  def show
    @item = Item.get_cached(params[:id])#where(:id => params[:id]).includes(:item_attributes).last
  
    @related_items = Item.all[0..2]
    @invitation=Invitation.new(:item_id => @item, :item_type => @item.itemtype)
    user_follow_type(@item, current_user)
    @tip = Tip.new
    @contents = Tip.order('created_at desc').limit(5)
    @review = ReviewContent.new
  end

  def related_products
    @item = Item.where(:id => params[:id]).last    
    @follow_type = params[:follow_type]
    respond_to do |format|
      format.js { render :partial=> 'itemrelationships/relateditem', :collection => @item.unfollowing_related_items(current_user, 2) }
    end

  end
end
