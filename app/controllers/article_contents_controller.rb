class ArticleContentsController < ApplicationController
  before_filter :authenticate_user!

  def create
    #not used anywhere
    @item_id = params[:item_id]
    #for bookmark
    @external = params[:external]

    #for article content create or submit
    @article_create = params[:article_create] 
    ids = params[:articles_item_id] || params[:article_create_item_id]
    @article=ArticleContent.saveContent(params[:article_content] || params[:article_create],current_user,ids)
    # Resque.enqueue(ContributorPoint, current_user.id, @article.id, Point::PointReason::CONTENT_CREATE) unless @article.errors.any?
    Point.add_point_system(current_user, @article, Point::PointReason::CONTENT_SHARE) unless @article.errors.any?
    flash[:notice]= "Article uploaded"
    respond_to do |format|
      format.js
    end
  end
  
  def download
    @article_category = ArticleCategory.find(params[:article_content][:article_category_id])
    url=params['article_content']['url']
    if url.nil?
      @article=ArticleContent.create(params[:article_content])
    else
      @article,@images = ArticleContent.CreateContent(url,current_user)
    end
  end # action ends here
  
  def bmarklet
    @article,@images = ArticleContent.CreateContent(params[:url],current_user)
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