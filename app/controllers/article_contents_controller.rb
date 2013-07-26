class ArticleContentsController < ApplicationController
 before_filter :authenticate_user!,:except => [:bmarklet]
  def create
    #not used anywhere
    #me = FbGraph::User.me(current_user.token)
  #me.feed!(
  #:message => 'Testing fb post from Rails App.',
#) 
     if params[:article_content][:sub_type] == "Deals" 
       if !params[:article_content][:field3]
         params[:article_content][:field3] = "0"
      end
    end  
    
    if params['article_content']['url']
      if params['article_content']['url'].include?("?utm_source=feedburner")
        params['article_content']['url'] = params['article_content']['url'].split("?")[0]
      end
    end  
    
   if params['article_content']['title'] == ''
      @title = false
   #elsif params['article_content']['url']  && !ArticleContent.where(:url => params['article_content']['url']).blank?
    # @duplicate_url = 'true'
   else
    @item_id = params[:item_id]
    #for bookmark
    @external = params[:external]
    @item = Item.find(params[:default_item_id]) unless params[:default_item_id].empty?
    #for article content create or submit
    @article_create = params[:article_content_create]
    ids = params[:articles_item_id] || params[:article_create_item_id]
    unless ids.blank?
      score =  (params[:article_content][:sub_type] == ArticleCategory::REVIEWS) ? params[:score] : ""
    if params[:article_content][:sub_type]!= "Photo" 
       params["article_content"].delete("content_photos_attributes")
    end 
   if (params[:noincludethumbnail] == 'on')
      params[:article_content][:thumbnail] = ''
   end  
    @article=ArticleContent.saveContent(params[:article_content] || params[:article_create],current_user,ids, request.remote_ip, score)
      
    # Resque.enqueue(ContributorPoint, current_user.id, @article.id, Point::PointReason::CONTENT_CREATE) unless @article.errors.any?
   if params[:submit_url] == 'submit_url'
      ContentPhoto.save_url_content_to_local(@article) 
   end
    
    if ((params[:article_content][:sub_type] == "Photo" || params[:submit_url] == 'submit_url') && (!@article.content_photos.first.nil?))
      @article.update_attribute('thumbnail',@article.content_photos.first.photo.url(:thumb)) 
    else
       Content.save_thumbnail_using_uploaded_image(@article)
     end    
   
     if((params[:article_content][:sub_type] == "Reviews"))
       @defaultitem = Item.find(ids[0])
       @item1 = Item.find(params[:articles_item_id])
       @item1.add_new_rating(@article) if @article.id!=nil
    end
  # unless @article.errors.any?     
  #  @article.rate_it(params[:article_content][:field1],1) unless params[:article_content][:field1].nil? 
  #  end
   # Point.add_point_system(current_user, @article, Point::PointReason::CONTENT_SHARE) unless @article.errors.any?
   UserActivity.save_user_activity(current_user,@article.id,"created",@article.sub_type,@article.id,request.remote_ip)                if @article.id!=nil
   session[:content_id] = @article.id
   if current_user.total_points < 10
     @article.update_attribute('status',Content::SENT_APPROVAL) 
     @display = 'false'
   elsif @article.url!=nil
     Point.add_point_system(current_user, @article, Point::PointReason::CONTENT_SHARE) unless @article.errors.any?
   else
      Point.add_point_system(current_user, @article, Point::PointReason::CONTENT_CREATE) unless @article.errors.any?  
   end
   @facebook_post = params[:facebook_post]
   Follow.content_follow(@article,current_user) if @article.id!=nil
   # @article,@images = ArticleContent.CreateContent(@article.url,current_user) unless @article.url.blank?
    if params['article_content']['url'] && @article.id!=nil
       url = params['article_content']['url']
       url = "http://#{url}" if URI.parse(url).scheme.nil?
       host = URI.parse(url).host.downcase
     @article.update_attribute('domain',host.start_with?('www.') ? host[4..-1] : host)
   end   
   else
     @tag = 'false'
   end  
   end
   unless(@article.nil?)
        @article.update_facebook_stats
   end
    flash[:notice]= "Article uploaded"
    respond_to do |format|
      format.js
  end
 end
 
 
  def update
    #@default_id= params[:default_item_id]
     if params[:article_content][:sub_type] == "Deals" 
       if !params[:article_content][:field3]
         params[:article_content][:field3] = "0"
      end
    end  
    @item = Item.find(params[:default_item_id]) if params[:default_item_id] != ""
    ids = params["edit_articles_item_id_#{params[:id]}"] || params[:article_create_item_id]
    item_id = params[:default_item_id].blank? ? params["edit_articles_item_id_#{params[:id]}"] : Item.find(params[:default_item_id])
    #ids = params[:articles_item_id] || params[:article_create_item_id]
    if params[:article_content][:sub_type]!= "Photo"
       params.delete("content_photos_attributes")
    end 
    art = ArticleContent.find(params[:id])
    rating = art.field1.to_f rescue 0.0
    
    @content =ArticleContent.update_content(params[:id], params[:article_content] || params[:article_create],current_user,ids)
    if params[:submit_url] == 'submit_url' && art.thumbnail!= @content.thumbnail
      ContentPhoto.update_url_content_to_local(@content)
    end
     if params[:article_content][:sub_type] == 'Photo' || params[:submit_url] == 'submit_url'
       @content.update_attribute('thumbnail',(@content.content_photos.first.photo.url(:thumb) rescue nil))
     else
       Content.save_thumbnail_using_uploaded_image(@content)
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
    if (art.sub_type == "Reviews")
      Item.find(item_id).update_remove_rating(rating, @content,true)
      @content.update_facebook_stats
    #elsif (art.sub_type != "Reviews" && @content.sub_type ="Reviews")
     # add_new_rating(@content)
    end 
    if @content.url!=nil 
     UserActivity.update_user_activity(current_user,@content.id,@content.sub_type) 
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
      if url.include?("?utm_source=feedburner")
         url = url.split("?")[0]
      end  
      @article,@images = ArticleContent.CreateContent(url,current_user)
      
      @article.sub_type = params[:article_content][:sub_type]
    end
    @related_items = article_search_by_relevance(@article)
    #@related_items = Array.new
    @previous_content = ArticleContent.where(:url => params['article_content']['url']).first
   if params['article_content']['url']  && !@previous_content.blank?
     @duplicate_url = 'true'
   end  
    for row in @related_items
    logger.info row[:value]
    end
  end # action ends here
  
  def article_search_by_relevance(article)
    search_type = Product.search_type(params[:search_type])
    @items = Sunspot.search(search_type) do
        fulltext article.title do
          fields :nameformlt
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
      
      {:id => item.id, :value => item.get_name, :imgsrc =>image_url, :type => type, :url => url }
    }
    return results
 end
 
 def destroy
    @content = Content.find(params[:id])
    @content.update_attribute(:status, Content::DELETE_STATUS)
    @content.remove_user_activities
    rating = @content.field1.to_f rescue 0.0
    if @content.sub_type == "Reviews"
      @content.items.first.update_remove_rating(rating,@content,false)
    end  
  #@item.destroy
    @detail = params[:detail]
    if @detail == "true"
      @itemtype = @content.items.first.itemtype.itemtype
      if @itemtype == "Car Group" || @itemtype == "Manufacturer"
        @itemtype = "Car"
      end
    end  
  end
  
  def bmarklet
    #@article_content = ArticleContent.new
   if current_user 
    #@article,@images = ArticleContent.CreateContent("http://www.plannto.com/contents/12959",current_user)
     #params[:url] = "http://support.google.com/webmasters/bin/answer.py?hl=en&answer=1466"
    @previous_content = ArticleContent.where(:url => params[:url]).first
   if params['url']  && !@previous_content.blank?
     @duplicate_url = 'true'
   end
    @article,@images = ArticleContent.CreateContent(params[:url],current_user)
    @article_content= @article
    @external = params[:external]
   end 
    #@article_string = render_to_string :partial => "article" 
    respond_to do |format|
      format.html { render :layout => false }
      #format.js
   end
  end
  
  def new_popup
     @title = params[:title]
     @pros = params[:pros]
     @cons = params[:cons]
     @field1 = params[:field1]
     @field2 = params[:field2]
     @field3 = params[:field3]
     @field4 = params[:field4]
     @rating = params[:rating]
     @description = params[:description]
     @pop_up = "true"
    if params[:url] && params[:content].blank?
      @content = @article_content = ArticleContent.new 
    else
      @content = @article_content = Content.find(params[:content]) rescue nil
    end  
     @item = Item.find(params[:item]) rescue nil
    
     @items = Item.where("id in (#{@content.related_items.collect(&:item_id).join(',')})") rescue nil
     @url = "true" if params[:url]
      @article_categories = ArticleCategory.by_itemtype_id(@content.itemtype_id).map { |e|[e.name, e.id] } if @content
     @detail = "true" if @content
    respond_to do |format|
      format.html { render :layout => false }
      #format.js
    end
  end
  
  def bmark_create
    ids = params[:articles_item_id]
    @article=ArticleContent.saveContent(params[:article_content],current_user,ids) unless ids.empty?
    Follow.content_follow(@article,current_user) if @article
    flash[:notice]= "Article uploaded"

    respond_to do |format|
      format.js
    end
  end
 end
