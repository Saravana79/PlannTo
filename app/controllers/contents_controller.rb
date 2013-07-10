class ContentsController < ApplicationController
  before_filter :authenticate_user!, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type,:my_feeds]
  before_filter :get_item_object, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
  before_filter :store_location, :only => [:show]
  before_filter :set_waring_message,:only => [:show]
  before_filter :log_impression, :only=> [:show]
  #cache_sweeper :content_sweeper
  #layout :false
  layout "product"
  include FollowMethods
  
  
  def log_impression
    @article = Content.find(params[:id])
  # this assumes you have a current_user method in your authentication system
    @article.impressions.create(ip_address: request.remote_ip,user_id:(current_user.id rescue ''))
   end
   
   def filter
     if params[:item_type_id].is_a?  Array
       itemtype_id = params[:itemtype_id] 
     else
       itemtype_id  = params[:itemtype_id].split(",")
     end 
     filter_params = {"sub_type" => get_sub_type(params[:sub_type],   itemtype_id)}    
     filter_params["order"] = get_sort_by(params[:sort_by])
     filter_params["itemtype_id"] =  itemtype_id 
     if  params[:guide]!="" && params[:items]!=""
       filter_params.delete("itemtype_id") 
    end 
     filter_params["search_type"] = params[:search_type]
     if  itemtype_id.present?
        if params[:search_type] == "Myfeeds" || params[:search_type] == "admin_feeds"
          @items,@item_types,@article_categories,@root_items  = Content.follow_items_contents(current_user,itemtype_id,'category')
           filter_params["content_ids"] = Content.follow_content_ids(current_user,filter_params["sub_type"]) if params[:search_type] == "Myfeeds"
          filter_params["root_items"] = @root_items if params[:search_type] == "Myfeeds"
          filter_params["items_id"] = @items.split(",") if params[:search_type] == "Myfeeds"
          filter_params["created_by"] =  params[:search_type] == "Myfeeds"? User.get_follow_users_id(current_user) : User.find(:all).collect(&:id)
       end  
      if params[:search_type] != "Myfeeds"  
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
        elsif (item.type == "AttributeTag")
          filter_params["item_relations"]  = Item.get_related_item_list_first(item.id)
        else
          filter_params["items"] = items
        end
      else
      filter_params["items"] = items
      end
    end
    end
    if params[:user]
      filter_params["user"] = params[:user]
    end  
    #filter_params["page"] = params[:page] if params[:page].present?
    filter_params["page"] = params[:page]  
    filter_params["status"] = 1
    filter_params["guide"] = params[:guide] if params[:guide].present?
    if params[:search_type] == "Myfeeds" || params[:search_type] == "admin_feeds"
      @contents = Content.my_feeds_filter(filter_params,current_user)
    else      
       @contents = Content.filter(filter_params)
        if params[:guide]!="" && @contents.size == 0 && params[:items]!="" 
          filter_params.delete("items")
          @guide_itemtype = "true"
          filter_params["page"] = 1
          filter_params["itemtype_id"] =  itemtype_id 
          @contents = Content.filter(filter_params)
      end
    end  
    end
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
        elsif (item.type == "AttributeTag")
          item_ids  = Item.get_related_item_list_first(item.id)
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
  
  def search_autocomplete_list
    @results = Sunspot.search(Content) do
      keywords params[:term].gsub("-",""), :fields => :name
      with :sub_type, "#{params[:sub_type]}"
      with :status, 1
    end
    results = @results.results.collect{|item|
    
      {:id => item.id, :value => "#{item.title}", :imgsrc =>"", :type => item.sub_type, :url =>  "" }
    }
    render :json => results
  end

  def feeds
    if params[:item_type_id].is_a?  Array
       itemtype_id = params[:itemtype_id] 
     else
       itemtype_id  = params[:itemtype_id].split(",")
    end 
    filter_params = {"sub_type" => get_sub_type(params[:sub_type], itemtype_id )}
    filter_params["itemtype_id"] = itemtype_id  
    if params[:user]
      filter_params["user"] = params[:user]
    end 
     if  params[:guide]!="" && params[:items]!=""
       filter_params.delete("itemtype_id") 
     end 
     filter_params["search_type"] = params[:search_type]
    if itemtype_id .present?
       if params[:search_type] == "Myfeeds" || params[:search_type] == "admin_feeds"
          @items,@item_types,@article_categories,@root_items  = Content.follow_items_contents(current_user,itemtype_id,'category')
           filter_params["content_ids"] = Content.follow_content_ids(current_user,filter_params["sub_type"]) if params[:search_type] == "Myfeeds"
          filter_params["root_items"] = @root_items if params[:search_type] == "Myfeeds"
          filter_params["items_id"] = @items.split(",") if params[:search_type] == "Myfeeds"
          filter_params["created_by"] =  params[:search_type] == "Myfeeds"? User.get_follow_users_id(current_user) : User.find(:all).collect(&:id)
       end   
      if params[:search_type] != "Myfeeds"  
       
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
        elsif (item.type == "AttributeTag")
          filter_params["item_relations"]  = Item.get_related_item_list_first(item.id)
        else
          filter_params["items"] = items
        end
      else
      filter_params["items"] = items
      end
      end
    end
     if  params[:guide]!="" && params[:search_type] == "guide_itemtype"
       filter_params.delete("items")
       filter_params["itemtype_id"] =  itemtype_id 
     end 
     filter_params["page"] = params[:page]  
     filter_params["status"] = 1
     filter_params["guide"] = params[:guide] if params[:guide].present?
     filter_params["order"] = get_sort_by(params[:sort_by]) 
     if params[:search_type] == "Myfeeds" || params[:search_type] == "admin_feeds"
        @contents = Content.my_feeds_filter(filter_params,current_user)
     else      
      @contents = Content.filter(filter_params)
      if params[:guide]!="" && @contents.size == 0 && params[:items]!="" && params[:search_type]!= "guide_itemtype"
         filter_params.delete("items")
         @guide_itemtype = "true"
         filter_params["page"] = 1
         filter_params["itemtype_id"] =  itemtype_id 
         @contents = Content.filter(filter_params)
      end
    end  
    end
    respond_to do |format|
      format.js {
        render "contents/filter"
      #render "feed", :layout =>false, :locals => {:contents_string => render_to_string(:partial => "contents", :locals => {:params => params}) }
      }
    end
  end
  
  def search_guide
    @static_page1 = "true"
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
      @itemtype = Itemtype.find_by_itemtype(params[:itemtype].singularize.camelize.constantize) if params[:itemtype].present?
      
     # @article_categories = ArticleCategory.by_itemtype_id(0).map { |e|[e.name, e.id]  }
    end
    
    if !@item.nil?
      # @item_id = params[:item_id] if params[:item_id].present?
      sub_type = get_sub_type('All',   "") #@article_categories.collect(&:name)
      filter_params = {"sub_type" => sub_type}
      filter_params["order"] = get_sort_by(params[:sort_by])
     if param_item_id.present?
        @item_id = param_item_id
        item = Item.find(@item_id)
        if (item.type == "Manufacturer") || (item.type == "CarGroup")
          filter_params["item_relations"] = item.related_cars.collect(&:id)
        elsif (item.type == "AttributeTag")
          filter_params["item_relations"]  = Item.get_related_item_list_first(item.id)
        else
          filter_params["items"] = @item_id
        end
    end
    @popular_topics = Item.popular_topics(@itemtype.itemtype)
    filter_params["items"] = params[:item_id]
    #filter_params["itemtype_id"] = @itemtype.id  if @item.nil?
    #unless item.nil?
     #filter_params["itemtype_id"] = item.get_base_itemtypeid
     #@itemtype = Itemtype.find item.get_base_itemtypeid
    #end
    filter_params["guide"] = @guide.id
    filter_params["page"] = params[:page] if params[:page].present?
    filter_params["status"] = 1
    @contents = Content.filter(filter_params)
  end  
    if @contents.try(:size) == 0 || @item.nil?
       
       #session[:guide] = "itemtype"
       sub_type = get_sub_type('All',   "") #@article_categories.collect(&:name)
       filter_params = {"sub_type" => sub_type}
       filter_params["order"] = get_sort_by(params[:sort_by])
       filter_params["itemtype_id"] = @itemtype.id  
    unless item.nil?
      filter_params["itemtype_id"] = item.get_base_itemtypeid
      @itemtype = Itemtype.find item.get_base_itemtypeid
    end
    filter_params["guide"] = @guide.id
    filter_params["page"] = params[:page] if params[:page].present?
    filter_params["status"] = 1
    @contents = Content.filter(filter_params)
  end  
    
  end

  def show
    @content = Content.find(params[:id])
    #session[:content_warning_message] = "true"
    session[:warning] = "true"
    session[:itemtype] = @content.items.first.get_base_itemtype rescue ""
    content_as_item = ContentAsItem.where(:content_id => @content.id).first
   # @content.facebook_count_save 
    if  content_as_item.blank?
      per_page = params[:per_page].present? ? params[:per_page] : 6
      page_no  = params[:page_no].present? ? params[:page_no] : 1
      # @items = Item.where("id in (#{@content.related_items.collect(&:item_id).join(',')})")
      #frequency = ((@content.title.split(" ").size) * (0.3)).to_i
      frequency = 1
      results = Sunspot.more_like_this(@content) do
      fields :title
      minimum_term_frequency 1
      boost_by_relevance true
      minimum_word_length 2
      paginate(:page => page_no, :per_page => per_page)
    end
      @related_contents = results.results
      #@popular_items = ItemContentsRelationsCache.where(:content_id => @content.id).limit(5)
      @popular_items = Item.find_by_sql("select * from items where id in (select item_id from item_contents_relations_cache where content_id =#{@content.id}) and itemtype_id in (1, 6, 12, 13, 14, 15) and status in ('1','2')  order by id desc limit 4")
      @popular_items_ids  = @popular_items.map(&:id).join(",")
      @comment = Comment.new
      render :layout => "product"
      return true
    else
     @item = Item.find(content_as_item.item_id)
      redirect_to @item.get_url()
  end   
  end
  
  def search_related_contents
    @content = Content.find(params[:id])
    #frequency = ((@content.title.split(" ").size) * (0.3)).to_i
    #if frequency == 0
      frequency = 1
    #end
    per_page = params[:per_page].present? ? params[:per_page] : 6
    page_no  = params[:page_no].present? ? params[:page_no] :2
    results = Sunspot.more_like_this(@content) do
      fields :title      
      boost_by_relevance true
      minimum_term_frequency frequency
      minimum_word_length 2
      paginate(:page => page_no, :per_page => per_page)
    end
    puts results.results.count
    puts results.results[0]
    @related_contents = results.results
  end
  
  def quick_new
  @share = params[:sharecontent]
  @item = Item.find(params[:item_id]) if !params[:item_id].blank?
  if @share!='' && !@share.nil?
     @content = ArticleContent.new
     @content.sub_type = params[:category]
    @article_content = @content
    @article_categories = ArticleCategory.get_by_itemtype(0)
    @items = Array.new
  else    
    if params[:category] == "Reviews"
      @content = ReviewContent.new
    
    elsif params[:category] == "Q" || params[:category] == "QandA"
      @content = QuestionContent.new
    else
      @content = ArticleContent.new
      @content.content_photos.build
    end
    @content.sub_type = params[:category]
    @article_content = @content
    @article_categories = ArticleCategory.get_by_itemtype(0)
    @items = Array.new
  end  
  if(@items.empty? && !@item.nil?)
    @items << @item
  end    
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
    #this workaround is done to replace new line character before sending in js script. we need to find a better way to do this.
    if(@article_content.is_a? ArticleContent)
        @article_content.field4 = @article_content.field4.gsub("\n"," ").gsub("\r","") 
        @article_content.field3 = @article_content.field3.gsub("\n"," ").gsub("\r","") 
        @article_content.field2 = @article_content.field2.gsub("\n"," ").gsub("\r","") 
    end 
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
    per_page = params[:per_page].present? ? params[:per_page] : 6
    page_no  = params[:page_no].present? ? params[:page_no] : 1
   # @items = Item.where("id in (#{@content.related_items.collect(&:item_id).join(',')})")
   #frequency = ((@content.title.split(" ").size) * (0.3)).to_i
   frequency = 1
    results = Sunspot.more_like_this(@content) do
      fields :title
      minimum_term_frequency 1
      boost_by_relevance true
      minimum_word_length 2
      paginate(:page => page_no, :per_page => per_page)
    end
    @related_contents = results.results
    #@popular_items = ItemContentsRelationsCache.where(:content_id => @content.id).limit(5)
    @popular_items = Item.find_by_sql("select * from items where id in (select item_id from item_contents_relations_cache where content_id =#{@content.id}) and itemtype_id in (1, 6, 12, 13, 14, 15) and status in ('1','2')  order by id desc limit 4")
    @popular_items_ids  = @popular_items.map(&:id).join(",")
    @comment = Comment.new
  end

  def delete
    get_item_object
  end

  def destroy
    get_item_object
    @item.update_attribute(:status, Content::DELETE_STATUS)
    @item.remove_user_activities
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
    guide_ids = @content.guides.collect(&:id).join(',')
    @content.update_attribute(:content_guide_info_ids, "#{guide_ids}")

    respond_to do |format|
      format.js
    end
  end
  
  def my_feeds
    if current_user
      @items,@item_types,@article_categories,@root_items = Content.follow_items_contents(current_user,params[:item_types],params[:type])
      filter_params = {"sub_type" => @article_categories}
      filter_params["itemtype_id"] = @item_types 
     
       if @items.size > 0 and !@item_types.blank?
        if @items.is_a? Array
            items = @items
        else
          items = @items.split(",")
        end
       filter_params["items_id"] = items  unless params[:search_type] == "admin_feeds"
      
       filter_params["status"] = 1
       filter_params["created_by"] = params[:search_type] == "admin_feeds" ? User.find(:all).collect(&:id) : User.get_follow_users_id(current_user)
       filter_params["page"] = 1
       filter_params["root_items"] = @root_items if params[:search_type] != "admin_feeds"
       filter_params["guide"] = params[:guide] if params[:guide].present?
       filter_params["order"] = get_sort_by(params[:sort_by])
       @contents = Content.my_feeds_filter(filter_params,current_user)
    end
    respond_to do |format|
     format.js{ render "contents/my_feeds"}
      format.html
    end
  else
     redirect_to root_path
    end
  end
  
  def get_class_names
      @contents = Content.where(id: params[:ids])
      class_names = {}
      @contents.collect{|content| class_names.merge!(content.rating_classnames(current_user))}
    
    respond_to do |format|
      format.json{render json: class_names}
    end
    
  end
  
  
  private
  
  def set_waring_message
    unless request.referer.nil?
      if request.referer.include?("google")   
        session[:content_warning_message] = "true"  
        session[:http_referer] = request.referer
        return true
      end
     end
  end
  
  def get_item_object
    @item = Content.find(params[:id])
  end
  
  def get_sub_type(sub_type, itemtype_id)   
    if sub_type =="All"
      if itemtype_id.empty?
        return ArticleCategory.where("itemtype_id in (?)", 0).collect(&:name)
      else
        return ArticleCategory.where("itemtype_id in (?)", itemtype_id).collect(&:name).uniq
      end
      
     elsif sub_type =="QandA" || sub_type == "Q"
      return ["Q&A"]
     elsif sub_type == "Custom"
      return ["Reviews","Deals","Lists"]   
    else
      return sub_type.split(",")
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
