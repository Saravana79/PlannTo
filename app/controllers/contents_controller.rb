class ContentsController < ApplicationController

  layout :false
  def feed
    
    @contents = Content.filter(params.slice(:items, :type, :order, :limit, :page))
    
    respond_to do |format|
      format.html { render "feed", :locals => {:params => params} }
      format.js { render "feed", :locals => {:contents_string => render_to_string(:partial => "contents", :locals => {:params => params}) }}
    end
  end

  def show
    @content = Content.find(params[:id])
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
    @item = Item.find(params[:item_id])
    @article_content= @content = Content.find(params[:id])
    #put an if loop to check if its an article share. if yes then uncomment the link below
    #@article,@images = ArticleContent.CreateContent(url,current_user)
    @items = Item.where("id in (#{@content.related_items.collect(&:item_id).join(',')})")
    @article_categories = ArticleCategory.by_itemtype_id(@item.itemtype_id).map { |e|[e.name, e.id]  }
  end

  def update
    @item = Item.find(params[:default_item_id])
    @content = Content.find(params[:id])
    @content.update_with_items!(params[:plannto_content], params[:item_id])

  end

  

end
