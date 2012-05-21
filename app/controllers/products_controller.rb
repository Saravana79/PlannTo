class ProductsController < ApplicationController
  before_filter :authenticate_user!, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
  before_filter :get_item_object, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type, :review_it, :add_item_info]
  before_filter :all_user_follow_item, :if => Proc.new { |c| !current_user.blank? }
  
  layout 'product'
  
  include FollowMethods

  def index
    @itemtype = Itemtype.find_by_itemtype(params[:search_type].singularize.camelize.constantize)
@article_categories = ArticleCategory.by_itemtype_id(@itemtype.id)#.map { |e|[e.name, e.id]  }

  end

  def specification
    @item = Item.find_by_id(params[:id])
  end

  def show
    @item = Item.get_cached(params[:id])#where(:id => params[:id]).includes(:item_attributes).last
    @where_to_buy_items = Itemdetail.where("itemid = ?", params[:id]).includes(:vendor)
    @related_items = Item.get_related_items(@item, 3)
    @invitation=Invitation.new(:item_id => @item, :item_type => @item.itemtype)
    user_follow_type(@item, current_user)
    @tip = Tip.new
    @contents = Tip.order('created_at desc').limit(5)
    @review = ReviewContent.new
    @article_content=ArticleContent.new(:itemtype_id => @item.itemtype_id)
    @questions = QuestionContent.all
    @article_categories = ArticleCategory.by_itemtype_id(@item.itemtype_id).map { |e|[e.name, e.id]  }

    @top_contributors = @item.get_top_contributors
    
  end

  def related_products
    @item = Item.where(:id => params[:id]).last    
    @follow_type = params[:follow_type]
    respond_to do |format|
      format.js { render :partial=> 'itemrelationships/relateditem', :collection => @item.unfollowing_related_items(current_user, 2) }
    end

  end

  def review_it
  end

  def add_item_info
  end

  private

  def get_item_object
    @item = Item.find(params[:id])
  end
end
