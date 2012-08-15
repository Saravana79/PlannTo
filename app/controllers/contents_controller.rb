class ContentsController < ApplicationController
  before_filter :authenticate_user!, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
  before_filter :get_item_object, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
  before_filter :store_location, :only => [:show]
  #layout :false
  layout "product"
  include FollowMethods
  
  #TODO DO WE NEED THIS ACTION?
 # def feed

  #  @contents = Content.filter(params.slice(:items, :type, :order, :limit, :page))

   # logger.error("slice params " + params.slice(:items, :type, :order, :limit, :page).to_s)

    #respond_to do |format|
   #   format.html { render "feed", :layout =>false, :locals => {:params => params} }
   #   format.js { render "feed", :layout =>false, :locals => {:contents_string => render_to_string(:partial => "contents", :locals => {:params => params}) }}
   # end
  #end

  def filter
    
    filter_params = {"sub_type" => get_sub_type(params[:sub_type], params[:itemtype_id])}    
    filter_params["order"] = get_sort_by(params[:sort_by]) 
    filter_params["itemtype_id"] =params[:itemtype_id] if params[:itemtype_id].present?
    filter_params["items"] = params[:items].split(",") if params[:items].present?
    filter_params["status"] = 1
    filter_params["guide"] = params[:guide] if params[:guide].present?
    
    @contents = Content.filter(filter_params)
  end

  def search_contents
    sub_type = params[:content_search][:sub_type]== "All" ? Array.new : params[:content_search][:sub_type].split(",")
    item_ids = params[:content_search][:item_ids] == "" ? Array.new : params[:content_search][:item_ids].split(",")
    itemtype_ids = params[:content_search][:itemtype_ids] == "" ? Array.new : params[:content_search][:itemtype_ids].split(",")
    page = params[:content_search][:page] || 1    
    sort_by = get_sort_by(params[:content_search][:sort_by])

    search_list = Sunspot.search(Content ) do
      fulltext params[:content_search][:search] , :field => :name
      with :sub_type, sub_type if sub_type.size > 0
      with :item_ids, item_ids if item_ids.size > 0
      with :status, 1
      with :itemtype_ids, itemtype_ids if itemtype_ids.size > 0   
      order_by sort_by.to_sym, order_by_value.to_sym unless sort_by == ""
      paginate(:page => page, :per_page => 10 )
    end
    @contents = search_list.results
  end

  def feeds
    filter_params = {"sub_type" => get_sub_type(params[:sub_type], params[:itemtype_id])}
    filter_params["itemtype_id"] =params[:itemtype_id] if params[:itemtype_id].present?
    filter_params["items"] = params[:items].split(",") if params[:items].present?
    filter_params["page"] = params[:page] if params[:page].present?
    filter_params["status"] = 1
    filter_params["guide"] = params[:guide] if params[:guide].present?
    filter_params["order"] = get_sort_by(params[:sort_by])   
    @contents = Content.filter(filter_params)
    respond_to do |format|
      format.js {
        render "contents/filter"
      #render "feed", :layout =>false, :locals => {:contents_string => render_to_string(:partial => "contents", :locals => {:params => params}) }
      }
    end
  end
  
  def search_guide  
    @itemtype = Itemtype.find_by_itemtype(params[:itemtype].singularize.camelize.constantize)
    @guide = Guide.find_by_name params[:guide_type]
    @article_categories=  ArticleCategory.where("itemtype_id = ?", @itemtype.id)
    sub_type = @article_categories.collect(&:name)
    filter_params = {"sub_type" => sub_type}
    filter_params["order"] = get_sort_by(params[:sort_by])  
    filter_params = {"sub_type" => sub_type}
    filter_params["itemtype_id"] = @itemtype.id
    filter_params["guide"] = @guide.id
    filter_params["page"] = params[:page] if params[:page].present?
    filter_params["status"] = 1
    @contents = Content.filter(filter_params)
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
    @item.update_attribute(:status, Content::DELETE_STATUS)
  #@item.destroy
  end

  def update_guide
    @content = Content.find params[:content]
    guide = Guide.find params[:guide]

    if @content.guides.include? guide
      @content.guides.delete guide
    else
      @content.guides.push guide
    end  

    respond_to do |format|
      format.js
    end
  end

  private

  def get_item_object
    @item = Content.find(params[:id])
  end
  
  def get_sub_type(sub_type, itemtype_id)    
    if sub_type =="All"
      return ArticleCategory.where("itemtype_id = ?", itemtype_id).collect(&:name)
     elsif sub_type =="QandA"
      return "Q&A"
    else
      return params[:sub_type].split(",")
    end
  end
  
  def get_sort_by(sort_by)
    sort_by_value = params[:sort_by]
    if sort_by == "Newest"
      return "created_at desc"
    elsif sort_by == "Votes"
      return "total_votes desc"
    elsif sort_by == "Most Comments"
      return "comments_count desc"
    else
      if params[:sub_type] =="All"
        return "created_at desc"
      else
        return "total_votes desc"
      end
    end
    return "total_votes desc"
  end
end
