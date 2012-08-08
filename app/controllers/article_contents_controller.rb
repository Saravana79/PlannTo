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
      ContentPhoto.save_url_content_to_local(@article,params['article_content']['url']) 
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
     if params[:submit_url] == 'submit_url'
       ContentPhoto.update_url_content_to_local(@article,params[:article_content][:url])
    end
    @article=ArticleContent.update_content(params[:id], params[:article_content] || params[:article_create],current_user,ids)
     if params[:article_content][:sub_type] == 'Photo' || params[:submit_url] == 'submit_url'
       @article.update_attribute('thumbnail',@article.content_photo.photo.url(:thumb))
     end   
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
      #@article,@images = ArticleContent.CreateContent(url,current_user)
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
