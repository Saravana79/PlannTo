class ArticleContentsController < ApplicationController
  before_filter :authenticate_user!

  def create
    @article=ArticleContent.create(params[:article_content])
    @item_id = params[:item_id]
    ids = params[:articles_item_id]
    @article.save_with_items!(ids) unless ids.empty?
    flash[:notice]= "Article uploaded"

    respond_to do |format|
      format.js
    end
  end
  
  def download
    url=params['article_content']['url']
    if url.nil?
      @article=ArticleContent.create(params[:article_content])
    else
      @article = ArticleContent.CreateContent(url,current_user)
    end
    respond_to do |format|
      format.js
    end
  end # action ends here
end
