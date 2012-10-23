class ArticleContentsController < ApplicationController
  before_filter :authenticate_user!
  def create
    #not used anywhere
    
    @item_id = params[:item_id]
    #for bookmark
    @external = params[:external]
    @item = Item.find(params[:default_item_id]) unless params[:default_item_id].empty?
    #for article content create or submit
    @article_create = params[:article_content_create]
    ids = params[:articles_item_id] || params[:article_create_item_id]
    score =  (params[:article_content][:sub_type] == ArticleCategory::REVIEWS) ? params[:score] : ""
    if params[:article_content][:sub_type]!= "Photo"
       params.delete("content_photos_attributes")
   end 
   if (params[:noincludethumbnail] == 'on')
      params[:article_content][:thumbnail] = ''
   end  
    @article=ArticleContent.saveContent(params[:article_content] || params[:article_create],current_user,ids, request.remote_ip, score)
    # Resque.enqueue(ContributorPoint, current_user.id, @article.id, Point::PointReason::CONTENT_CREATE) unless @article.errors.any?
   if params[:submit_url] == 'submit_url'
     ContentPhoto.save_url_content_to_local(@article) 
   end   
   if ((params[:article_content][:sub_type] == "Photo" || params[:submit_url] == 'submit_url') && (!@article.content_photo.nil?))
     @article.update_attribute('thumbnail',@article.content_photo.photo.url(:thumb)) 
   end  
    if((params[:article_content][:sub_type] == "Reviews") && !params[:article_content][:field1].nil? && (params[:article_content][:field1] !="0"))
     @defaultitem = Item.find(ids[0])
     @defaultitem.add_new_rating(params[:article_content][:field1].to_f)
    end
  # unless @article.errors.any?     
  #  @article.rate_it(params[:article_content][:field1],1) unless params[:article_content][:field1].nil? 
  #  end
    Point.add_point_system(current_user, @article, Point::PointReason::CONTENT_SHARE) unless @article.errors.any?
   UserActivity.save_user_activity(current_user,@article.id,"created",@article.sub_type,@article.id,request.remote_ip)
   # @article,@images = ArticleContent.CreateContent(@article.url,current_user) unless @article.url.blank?
    flash[:notice]= "Article uploaded"
    respond_to do |format|
      format.js
  end
 end
 
 
  def update
    #@default_id= params[:default_item_id]
    @item = Item.find(params[:default_item_id]) if params[:default_item_id] != ""
    ids = params["edit_articles_item_id_#{params[:id]}"] || params[:article_create_item_id]
    #ids = params[:articles_item_id] || params[:article_create_item_id]
    if params[:article_content][:sub_type]!= "Photo"
       params.delete("content_photos_attributes")
    end 
    art = ArticleContent.find(params[:id])
    @content =ArticleContent.update_content(params[:id], params[:article_content] || params[:article_create],current_user,ids)
    if params[:submit_url] == 'submit_url' && art.thumbnail!= @content.thumbnail
      ContentPhoto.update_url_content_to_local(@content)
    end
     if params[:article_content][:sub_type] == 'Photo' || params[:submit_url] == 'submit_url'
       @content.update_attribute('thumbnail',(@content.content_photo.photo.url(:thumb) rescue nil))
     end
    @detail = params[:detail]  
    per_page = params[:per_page].present? ? params[:per_page] : 5
    page_no  = params[:page_no].present? ? params[:page_no] : 1
   # @items = Item.where("id in (#{@content.related_items.collect(&:item_id).join(',')})")
   frequency = ((@content.title.split(" ").size) * (0.3)).to_i
    results = Sunspot.more_like_this(@content) do
      fields :title
      minimum_term_frequency 1
      boost_by_relevance true
      minimum_word_length 2
      paginate(:page => page_no, :per_page => per_page)
    end
     @popular_items = Item.find_by_sql("select * from items where id in (select item_id from item_contents_relations_cache where content_id =#{@content.id}) and itemtype_id in (1, 6, 12, 13, 14, 15) and status in ('1','2')  order by id desc limit 4")
    @popular_items_ids  = @popular_items.map(&:id).join(",") 
    @related_contents = results.results   
  end
  
  def download
    @edit_form  = params[:save_instruction ] == "1" ? false : true
    @article = ArticleContent.new
    @images = Array.new
    #@default_item_id = params[:default_item_id]
    #@article_category = ArticleCategory.find(params[:article_content][:article_category_id])
    url=params['article_content']['url']
    if url.nil?
      @article=ArticleContent.create(params[:article_content])
    else
      @article,@images = ArticleContent.CreateContent(url,current_user)
      @article.sub_type = params[:article_content][:sub_type]
    end
    @related_items = article_search_by_relevance(@article)
    for row in @related_items
    logger.info row[:value]
    end
  end # action ends here
  
  def article_search_by_relevance(article)
  
  search_type = Product.search_type(params[:search_type])
    @items = Sunspot.search(search_type) do
        fulltext article.title do
          minimum_match 1
        end
      order_by :score,:desc
      #paginate(:page => 1, :per_page => 10)      
    end

    results = @items.results.collect{|item|

      image_url = item.image_url(:small)
    
     if(item.is_a? (Product))
        type = item.type.humanize
     elsif(item.is_a? (CarGroup))
        type = "Groups"
     elsif(item.is_a? (AttributeTag))
        type = "Groups"
     elsif(item.is_a? (ItemtypeTag))
        type = "Topics"
     else
        type = item.type.humanize
    end 
    
     # end
      url = item.get_url()
      # image_url = item.image_url
      
      {:id => item.id, :value => "#{item.name}", :imgsrc =>image_url, :type => type, :url => url }
    }
    return results
 end
 
 def destroy
    @content = Content.find(params[:id])
    @content.update_attribute(:status, Content::DELETE_STATUS)
    @content.remove_user_activities
  #@item.destroy
  end
  
  def bmarklet
    #@article_content = ArticleContent.new
    @article,@images = ArticleContent.CreateContent(params[:url],current_user)
    @article_content= @article
    @external = params[:external]
    #@article_string = render_to_string :partial => "article" 
    respond_to do |format|
      format.html { render :layout => false }
      #format.js
    end
  end
  
  def bmark_create
    ids = params[:articles_item_id]
    @article=ArticleContent.saveContent(params[:article_content],current_user,ids) unless ids.empty?
    flash[:notice]= "Article uploaded"

    respond_to do |format|
      format.js
    end
  end
 end
