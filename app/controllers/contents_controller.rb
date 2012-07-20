class ContentsController < ApplicationController
  before_filter :authenticate_user!, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
  before_filter :get_item_object, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
  before_filter :store_location, :only => [:show]
  #layout :false
  include FollowMethods
  def feed
    
    @contents = Content.filter(params.slice(:items, :type, :order, :limit, :page))
    
    respond_to do |format|
      format.html { render "feed", :layout =>false, :locals => {:params => params} }
      format.js { render "feed", :layout =>false, :locals => {:contents_string => render_to_string(:partial => "contents", :locals => {:params => params}) }}
    end
  end

  def filter
    if params[:sub_type] =="All"
      sub_type = ArticleCategory.where("itemtype_id = ?", params[:itemtype_id]).collect(&:name)
    else
      sub_type = params[:sub_type].split(",")
    end
    filter_params = {"sub_type" => sub_type}
    filter_params["order"] = "total_votes desc" unless (params[:sub_type] =="All" || params[:sub_type] == "Event")
    filter_params["itemtype_id"] =params[:itemtype_id] if params[:itemtype_id].present?
    filter_params["items"] = params[:items].split(",") if params[:items].present?
    @contents = Content.filter(filter_params)
  end
  
  def search_contents
    sub_type = params[:content_search][:sub_type]== "All" ? Array.new : params[:content_search][:sub_type].split(",")
    item_ids = params[:content_search][:item_ids] == "" ? Array.new : params[:content_search][:item_ids].split(",")
    page = params[:content_search][:page] || 1
       logger.info item_ids
    search_list = Sunspot.search(Content ) do
      fulltext params[:content_search][:search] , :field => :name
      with :sub_type, sub_type if sub_type.size > 0
      with :item_ids, item_ids if item_ids.size > 0
     #fulltext params[:content_search][:search] do
   #    keywords "", :fields => :name
      # keywords "", :fields => :description
       #:fields =>(:name => 2.0, :description)
     #end
     paginate(:page => page, :per_page => 10 )
     end
     @contents = search_list.results
     
    # render "contents/filter"
  end

  def feeds

    #@contents = Content.filter(params.slice(:items, :type, :order, :limit, :page))
    if params[:sub_type] =="All"
      sub_type = ArticleCategory.where("itemtype_id = ?", params[:itemtype_id]).collect(&:name)
    else
      sub_type = params[:sub_type].split(",")
    end
    filter_params = {"sub_type" => sub_type}
    filter_params["itemtype_id"] =params[:itemtype_id] if params[:itemtype_id].present?
    filter_params["items"] = params[:items].split(",") if params[:items].present?
    filter_params["page"] = params[:page] if params[:page].present?
    @contents = Content.filter(filter_params)
    respond_to do |format|
      format.js { render "feed", :layout =>false, :locals => {:contents_string => render_to_string(:partial => "contents", :locals => {:params => params}) }}
    end
  end

  def show
    @content = Content.find(params[:id])
    @items = Item.where("id in (#{@content.related_items.collect(&:item_id).join(',')})")
    @comment = Comment.new
    render :layout => "product"
  end

  def create
    @item = Item.find(params[:default_item_id])
    @content = PlanntoContent.new params[:content]
    @content.field1 = params[:type]
		@content.user = current_user	
    @content.save_with_items!(params[:item_id])
  end

  def edit
    if params[:item_id].present?
      @item = Item.find(params[:item_id]) unless params[:item_id] == ""
    end
    @article_content= @content = Content.find(params[:id])
    @edit_form = true
    #put an if loop to check if its an article share. if yes then uncomment the link below
    #@article,@images = ArticleContent.CreateContent(url,current_user)
    @items = Item.where("id in (#{@content.related_items.collect(&:item_id).join(',')})")
    @article_categories = ArticleCategory.by_itemtype_id(@content.itemtype_id).map { |e|[e.name, e.id]  }

  end

  def update
    @item = Item.find(params[:default_item_id])
    @content = Content.find(params[:id])
    @content.update_with_items!(params[:plannto_content], params[:item_id])

  end

  def delete
    get_item_object
  end

  def destroy
    get_item_object
    #@item.destroy
  end

  private
  def get_item_object
    @item = Content.find(params[:id])
  end
end
