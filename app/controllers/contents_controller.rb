class ContentsController < ApplicationController
  before_filter :authenticate_user!, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type,:my_feeds]
  before_filter :get_item_object, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
  before_filter :store_location, :only => [:show]
  #layout :false
  layout "product"
  include FollowMethods
  
def filter
     if params[:item_type_id].is_a?  Array
       itemtype_id = params[:itemtype_id] 
     else
       itemtype_id  = params[:itemtype_id].split(",")
     end 
    filter_params = {"sub_type" => get_sub_type(params[:sub_type],   itemtype_id)}    
    filter_params["order"] = get_sort_by(params[:sort_by]) 
    filter_params["itemtype_id"] =  itemtype_id if  itemtype_id.present?
    
    if params[:items].present?
   
        if params[:items].is_a?  Array
          items = params[:items] 
        else
          items = params[:items].split(",")
         end 
        if items.size == 1
        item = Item.find(items[0])
        if (item.type == "Manufacturer") || (item.type == "CarGroup")
          filter_params["item_relations"] = item.related_cars.collect(&:id)
        else
          filter_params["items"] = items
        end
      else
      filter_params["items"] = items
      end
    end
    
    filter_params["status"] = 1
    filter_params["guide"] = params[:guide] if params[:guide].present?
    
    @contents = Content.filter(filter_params)
    
  end

  def search_contents
    sub_type = params[:content_search][:sub_type]== "All" ? Array.new : params[:content_search][:sub_type].split(",")
    item_ids = params[:content_search][:item_ids] == "" ? Array.new : params[:content_search][:item_ids].split(",")
    itemtype_ids = params[:content_search][:itemtype_ids] == "" ? Array.new : params[:content_search][:itemtype_ids].split(",")
    page = params[:content_search][:page] || 1    
    #sort_by = get_sort_by(params[:content_search][:sort_by])
    
    sort_by_value = params[:content_search][:sort_by]
    if sort_by_value == "Newest"
      sort_by =   "created_at"
      order_by_value = "desc"
    elsif sort_by_value == "Votes"
      sort_by = "total_votes"
      order_by_value = "desc"
    elsif sort_by_value == "Most Comments"
      sort_by = "comments_count"
      order_by_value = "desc"
    else
      order_by_value = "desc"
      if params[:sub_type] =="All"
        sort_by =   "created_at"
     else
        sort_by =   "total_votes"
     end
    end   
      if item_ids.size == 1
        item = Item.find(item_ids[0])
        if (item.type == "Manufacturer") || (item.type == "CarGroup")
          item_ids = item.related_cars.collect(&:id)
          itemtype_ids = Array.new
        end
      end
    search_list = Sunspot.search(Content ) do
      fulltext params[:content_search][:search] , :field => :name
      with :sub_type, sub_type if sub_type.size > 0
      with :item_ids, item_ids if item_ids.size > 0
      with :status, 1
      with :itemtype_ids, itemtype_ids if itemtype_ids.size > 0   
      order_by sort_by.to_sym unless sort_by == ""
      paginate(:page => page, :per_page => 10 )
    end
    @contents = search_list.results
  end

  def feeds
    if params[:item_type_id].is_a?  Array
       itemtype_id = params[:itemtype_id] 
     else
       itemtype_id  = params[:itemtype_id].split(",")
    end 
    filter_params = {"sub_type" => get_sub_type(params[:sub_type], itemtype_id )}
    filter_params["itemtype_id"] = itemtype_id  if itemtype_id .present?
    if params[:items].present?
       if params[:items].is_a?  Array
          items = params[:items] 
        else
          items = params[:items].split(",")
        end 
      if items.size == 1
        item = Item.find_by_id(items[0])
        if (item.type == "Manufacturer") || (item.type == "CarGroup")
          filter_params["item_relations"] = item.related_cars.collect(&:id)
        else
          filter_params["items"] = items
        end
      else
      filter_params["items"] = items
      end
    end
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
   
    @guide = Guide.find_by_name params[:guide_type]
    #@article_categories= ArticleCategory.where("itemtype_id = ?", @itemtype.id)
    @item = item = Item.where("id = ? or slug = ?", params[:item_id], params[:item_id]).first
    param_item_id = item.try(:id)
    
    if (item.is_a? Product)
      @article_categories = ArticleCategory.get_by_itemtype(item.get_base_itemtypeid) #ArticleCategory.where("itemtype_id = ?", item.get_base_itemtypeid)
       @itemtype = Itemtype.find_by_itemtype(params[:itemtype].singularize.camelize.constantize)
     # @article_categories = ArticleCategory.by_itemtype_id(@item.itemtype_id).map { |e|[e.name, e.id]  }
    else
      @article_categories = ArticleCategory.get_by_itemtype(0) #ArticleCategory.where("itemtype_id = ?", 0)
      @itemtype = Itemtype.find_by_itemtype(params[:itemtype].singularize.camelize) if params[:itemtype].present?
      
     # @article_categories = ArticleCategory.by_itemtype_id(0).map { |e|[e.name, e.id]  }
    end 
    
   # @item_id = params[:item_id] if params[:item_id].present?
    sub_type = get_sub_type('All',   "") #@article_categories.collect(&:name)
    filter_params = {"sub_type" => sub_type}
    filter_params["order"] = get_sort_by(params[:sort_by])
    if param_item_id.present?
      @item_id = param_item_id
        item = Item.find(@item_id)
        if (item.type == "Manufacturer") || (item.type == "CarGroup")
          filter_params["item_relations"] = item.related_cars.collect(&:id)
        else
          filter_params["items"] = @item_id
        end
    end
    #filter_params["items"] = params[:item_id].split(",") if params[:item_id].present?
    filter_params["itemtype_id"] = @itemtype.id unless @itemtype.nil?
    unless item.nil?
     filter_params["itemtype_id"] = item.get_base_itemtypeid
     @itemtype = Itemtype.find item.get_base_itemtypeid
    end
    filter_params["guide"] = @guide.id
    filter_params["page"] = params[:page] if params[:page].present?
    filter_params["status"] = 1
    @contents = Content.filter(filter_params)
  end

  def show
    @content = Content.find(params[:id])
    per_page = params[:per_page].present? ? params[:per_page] : 5
    page_no  = params[:page_no].present? ? params[:page_no] : 1
   # @items = Item.where("id in (#{@content.related_items.collect(&:item_id).join(',')})")
   frequency = ((@content.title.split(" ").size) * (0.3)).to_i
    results = Sunspot.more_like_this(@content) do
      fields :title
      minimum_term_frequency frequency
      paginate(:page => page_no, :per_page => per_page)
    end
    @related_contents = results.results
    @comment = Comment.new
    render :layout => "product"
  end
  
  def search_related_contents
    @content = Content.find(params[:id])
    #frequency = ((@content.title.split(" ").size) * (0.3)).to_i
    #if frequency == 0
      frequency = 1
    #end
    per_page = params[:per_page].present? ? params[:per_page] : 5
    page_no  = params[:page_no].present? ? params[:page_no] :2
    results = Sunspot.more_like_this(@content) do
      fields :title      
      #boost_by_relevance true
      minimum_term_frequency frequency
      minimum_word_length 2
      paginate(:page => page_no, :per_page => per_page)
    end
    @related_contents = results.results
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
    @detail = params[:detail]
    #put an if loop to check if its an article share. if yes then uncomment the link below
    #@article,@images = ArticleContent.CreateContent(url,current_user)
    @items = Item.where("id in (#{@content.related_items.collect(&:item_id).join(',')})")
    @article_categories = ArticleCategory.by_itemtype_id(@content.itemtype_id).map { |e|[e.name, e.id] }

  end

  def update
    @item = Item.find(params[:default_item_id])
    @content = Content.find(params[:id])
    @content.update_with_items!(params[:plannto_content], params[:item_id])
    @detail = params[:detail]
     results = Sunspot.more_like_this(@content) do
      fields :title
      minimum_term_frequency 1
    end
    @related_contents = results.results
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
  
  def my_feeds
    if current_user
      @items,@item_types,@article_categories = Content.follow_items_contents(current_user,params[:item_types])
      filter_params = {"sub_type" => @article_categories}
      filter_params["itemtype_id"] =@item_types 
    
      if @items.size > 0 and !@item_types.blank?
        if @items.is_a? Array
            items = @items
        else
          items = @items.split(",")
        end
        if items.size == 1
          item = Item.find(items[0])
        if (item.type == "Manufacturer") || (item.type == "CarGroup")
          filter_params["item_relations"] = item.related_cars.collect(&:id)
        else
          filter_params["items"] = items
        end
       else
         filter_params["items"] = items
       end
       filter_params["status"] = 1
       filter_params["guide"] = params[:guide] if params[:guide].present?
       filter_params["order"] = "created_at desc"
       @contents = Content.filter(filter_params)
    end
    respond_to do |format|
     format.js{ render "contents/my_feeds"}
      format.html
    end
  else
     redirect_to root_path
    end
  end
  
  private

  def get_item_object
    @item = Content.find(params[:id])
  end
  
  def get_sub_type(sub_type, itemtype_id)   
    if sub_type =="All"
      if itemtype_id.empty?
      return ArticleCategory.where("itemtype_id in (?)", 0).collect(&:name)
      else
      return ArticleCategory.where("itemtype_id in (?)", itemtype_id).collect(&:name)
      end
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
