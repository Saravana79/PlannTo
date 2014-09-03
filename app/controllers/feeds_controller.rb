class FeedsController < ApplicationController
  layout false
  before_filter :authenticate_admin_user!, :except => [:article_details]
  skip_before_filter :cache_follow_items, :store_session_url, :only => [:article_details]

  def index
    @feed = Feed.new()
    @categories = ["Mobile", "Tablet", "Camera", "Games", "Laptop", "Car", "Bike", "Cycle"]
    @feeds = Feed.all
  end

  def create
    feed = Feedzirra::Feed.fetch_and_parse(params[:feed][:url])
    if (!feed.blank? && feed != 0)
      categories = params[:feed][:category] ? params[:feed][:category].join(",") : ""
      @feed = Feed.create(url: feed.feed_url, title: feed.title, category: categories, created_by: current_user.id, process_type: "feed", process_value: "rss", :priorities => params[:feed][:priorities])
    end
    redirect_to feeds_path
  end

  def process_feeds
    Feed.process_feeds()
    flash[:notice] = "FeedUrls are Successfully Updated"
    redirect_to feeds_path
  end

  def feed_urls
    params[:page_loaded_time] ||= Time.now.utc
    @loaded_time = params[:page_loaded_time]
    params[:feed_urls_sort_by] ||= "published_at"
    params[:feed_urls_order_by] ||= "desc"

    # sort =
    condition = params[:page_loaded_time].blank? ? "1=1" : "created_at < '#{params[:page_loaded_time]}' "
    intial_condition = condition
    unless params[:search].blank?
      #condition = "1=1"
      condition = condition + " and priorities = #{params[:search][:priorities]}" unless params[:search][:priorities].blank?
      condition = condition + " and category like '%#{params[:search][:category]}%'" unless params[:search][:category].blank?
      condition = condition + " and status = #{params[:search][:status]}" unless params[:search][:status].blank?
      condition = condition + " and source = '#{params[:search][:source]}'" unless params[:search][:source].blank?
      #condition = condition == "1=1" ? "status != 1" : condition
    end

    if params[:commit] == "Clear"
      condition = intial_condition
      params[:search] = {}
    elsif params[:commit] != "Filter"
      params[:search] ||= {:status => 0}
      condition = condition == intial_condition ? "status = 0" : condition
    end

    @feed_urls = FeedUrl.where(condition).order("#{params[:feed_urls_sort_by]} #{params[:feed_urls_order_by]}").paginate(:page => params[:page], :per_page => 25)
    @categories = ["Mobile", "Tablet", "Camera", "Games", "Laptop", "Car", "Bike", "Cycle"]

    #Assign sources to memcache

    # FeedUrl.check_and_assign_sources_hash_to_cache_from_table()

    # @feed_urls = @feed_urls.paginate(:page => params[:page], :per_page => 25)

    if params[:page]
      return render :partial => "/feeds/feed_url_list", :layout => false
    end

    respond_to do |format|
      format.js
      format.html
    end
  end

  def article_details
    #for images

    @dwnld_url = "dwnld_url"
    @article_image = "article_image"
    @current_image_size = "current_image_size"
    @img_thumb = "img_thumb"
    @new_article_type ="new_article_type"
    @total_images = "total_images"
    @new_article_thumbnail = "new_article_thumbnail"
    @manual_image= "new_manual_image"
    @thumbnail_id = "new_thumbnail_url"
    @current_image_id = "current_image"
    @productReviewRatingField = "new_productReviewRatingField"
    @productReviewRating = "new_product_review_rating"


    @images = []
    @feed_url = FeedUrl.where("id = ?", params[:feed_url_id]).first

    @article_content = ArticleContent.find_by_url(@feed_url.url)

    unless @article_content.blank?
      @already_shared = true
      @feed_url.update_attributes!(:status => 1)
    else
      @already_shared = false
      @external = true
      @categories = ArticleCategory.get_by_itemtype(0).map {|x| x[0]}

      #if @feed_url.feed.process_type == "table"
      #  @article,@images = ArticleContent.CreateContent(@feed_url.url,current_user)
      #else
      #  summary = Nokogiri::HTML.fragment(@feed_url.summary)
      #  #@images << summary.children[0]['src'] #img source
      #  @article = ArticleContent.new(:url => @feed_url.url, :created_by => current_user.id)
      #  @meta_description = CGI.unescapeHTML(summary.children[1].text.gsub(/[^\x20-\x7e]/, '')) rescue summary
      #  @article.title = @feed_url.title
      #  @article.sub_type = @article.find_subtype(@article.title)
      #  @article.description = @meta_description unless @meta_description.blank?
      #
      #  doc = Nokogiri::HTML(open(@feed_url.url))
      #
      #  @images = ArticleContent.get_images_from_doc(doc, @images)
      #
      #  @article.thumbnail = @images.first if @images.count > 0
      #end

      if !@feed_url.blank?
        @article = ArticleContent.new(:url => @feed_url.url, :created_by => current_user.id)
        @article.title = @feed_url.title
        @article.sub_type = @article.find_subtype(@article.title)
        @article.description = @feed_url.summary
        @images = @feed_url.images.split(",")
        @article.thumbnail = @images.first if @images.count > 0
      end

      @article_content = @article
      @article.sub_type = "Others" if @article.sub_type.blank?
      params[:term] = @article.title
      #@results = Product.get_search_items_by_relavance(params)
    end

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
    @feed_url.update_attributes(:status => status)
    render :json => {:status => status, :feed_url_id => @feed_url.id}.to_json
  end

  def change_category
    @feed_url = FeedUrl.where("id = ?", params[:feed_url_id]).first
    category = params[:category] ||= "Others"

    unless @feed_url.blank?
      @feed_url.update_attributes!(:category => category)
    end
    render :json => {:category => category, :feed_url_id => @feed_url.id}.to_json
  end

  def load_suggestions
    Resque.enqueue(SourceItemProcess, "update_suggestions", Time.zone.now)
    render :text => "Load Suggestion Process Successfully Initiated"
  end

end
