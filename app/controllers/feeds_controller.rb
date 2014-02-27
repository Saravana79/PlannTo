class FeedsController < ApplicationController
  layout false
  before_filter :authenticate_admin_user!

  def index
    @feed = Feed.new()
    @categories = ["Mobile", "Tablet", "Camera", "Games", "Laptop", "Car", "Bike", "Cycle"]
    @feeds = Feed.all
  end

  def create
    feed = Feedzirra::Feed.fetch_and_parse(params[:feed][:url])
    if (!feed.blank? && feed != 0)
      categories = params[:feed][:category] ? params[:feed][:category].join(",") : ""
      @feed = Feed.create(url: feed.feed_url, title: feed.title, category: categories, created_by: current_user.id)
    end
    redirect_to feeds_path
  end

  def process_feeds
    Feed.process_feeds()
    flash[:notice] = "FeedUrls are Successfully Updated"
    redirect_to feeds_path
  end

  def feed_urls
    condition = "1=1"
    unless params[:search].blank?
      #condition = "1=1"
      condition = condition + " and category like '%#{params[:search][:category]}%'" unless params[:search][:category].blank?
      condition = condition + " and status = #{params[:search][:status]}" unless params[:search][:status].blank?
      condition = condition + " and source = '#{params[:search][:source]}'" unless params[:search][:source].blank?
      #condition = condition == "1=1" ? "status != 1" : condition
    end

    if params[:commit] == "Clear"
      condition = "1=1"
      params[:search] = {}
    end

    params[:search] ||= {}

    @feed_urls = FeedUrl.where(condition)

    @categories = ["Mobile", "Tablet", "Camera", "Games", "Laptop", "Car", "Bike", "Cycle"]
    @sources = FeedUrl.all.map(&:source).uniq
    @feed_urls = @feed_urls.paginate(:page => params[:page], :per_page =>20)

    respond_to do |format|
      format.js
      format.html
    end
  end

  def article_details
    @images = []
    @feed_url = FeedUrl.where("id =?", params[:feed_url_id]).first
    summary = Nokogiri::HTML.fragment(@feed_url.summary)
    @images << summary.children[0]['src']  #img source
    @article = ArticleContent.new(:url => @feed_url.url, :created_by => current_user.id)
    @meta_description = CGI.unescapeHTML(summary.children[1].text.gsub(/[^\x20-\x7e]/,''))
    @article.title = @feed_url.title
    sub_type = @article.find_subtype(@article.title)
    logger.info sub_type
    @article.sub_type = sub_type
    @article.description = @meta_description unless @meta_description.blank?
    @article.thumbnail = @images.first   if @images.count > 0
    @article_content = @article
    @categories = ArticleCategory.get_by_itemtype(0)
    @external = true

    @results = Product.get_search_items_by_relavance(params)

    respond_to do |format|
      format.html { render :layout => false }
      #format.js
    end
  end

  def change_status
    @feed_url = FeedUrl.where("id = ?", params[:feed_url_id]).first
    status = 0
    if (params[:mark_as] == "future")
      status = 2
    elsif (params[:mark_as] == "invalid")
      status = 3
    end
    #@feed_url.update_attributes(:status => status)
    render :json => {:status => status, :feed_url_id => @feed_url.id}.to_json
  end
end
