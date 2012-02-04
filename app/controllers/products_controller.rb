class ProductsController < ApplicationController
  before_filter :all_user_follow_item, :if => Proc.new { |c| !current_user.blank? }

  layout 'product'
  
  def index

  end

  def specification
    @item = Item.find_by_id(params[:id])
  end

  def show
    @item = Item.where(:id => params[:id]).includes(:item_attributes).last
    related_item_ids = RelatedItem.where(:item_id => @item.id).limit(3).collect(&:related_item_id)
    @related_items = Item.where(:id => related_item_ids)
    user_follow_type
  end

  def related_products
    @item = Item.where(:id => params[:id]).last    
    @follow_type = params[:follow_type]
    respond_to do |format|
      format.js { render :partial=> 'itemrelationships/relateditem', :collection => @item.unfollowing_related_items(current_user, 2) }
    end

  end
end
