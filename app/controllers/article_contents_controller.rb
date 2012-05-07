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
    @article=ArticleContent.saveContent(params[:article_content] || params[:article_create],current_user,ids)
    # Resque.enqueue(ContributorPoint, current_user.id, @article.id, Point::PointReason::CONTENT_CREATE) unless @article.errors.any?
    Point.add_point_system(current_user, @article, Point::PointReason::CONTENT_SHARE) unless @article.errors.any?
    flash[:notice]= "Article uploaded"
    respond_to do |format|
      format.js
    end
  end

  def update
    #@default_id= params[:default_item_id]
    @item = Item.find(params[:default_item_id])
    ids = params["edit_articles_item_id_#{params[:id]}"] || params[:article_create_item_id]
    #ids = params[:articles_item_id] || params[:article_create_item_id]
    @article=ArticleContent.update_content(params[:id], params[:article_content] || params[:article_create],current_user,ids)
  end
  
  def download
    @edit_form  = params[:save_instruction ] == "1" ? false : true
    
    #@default_item_id = params[:default_item_id]
    #@article_category = ArticleCategory.find(params[:article_content][:article_category_id])
    url=params['article_content']['url']
    if url.nil?
      @article=ArticleContent.create(params[:article_content])
    else
      @article,@images = ArticleContent.CreateContent(url,current_user)
      @article.sub_type = params[:article_content][:sub_type]
    end
  end # action ends here
  
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