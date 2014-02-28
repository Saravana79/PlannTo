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

  def process_rss_feeds
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
    @feed_urls = @feed_urls.paginate(:page => params[:page], :per_page => 20)

    respond_to do |format|
      format.js
      format.html
    end
  end

  def article_details
    @images = []
    @feed_url = FeedUrl.where("id =?", params[:feed_url_id]).first

    @article_content = ArticleContent.find_by_url(@feed_url.url)

    unless @article_content.blank?
      @already_shared = true
    else
      @already_shared = false
      @external = true
      @categories = ArticleCategory.get_by_itemtype(0)

      if @feed_url.process_type == "impression_missing"
        @article,@images = ArticleContent.CreateContent(@feed_url.url,current_user)
      else
        summary = Nokogiri::HTML.fragment(@feed_url.summary)
        @images << summary.children[0]['src'] #img source
        @article = ArticleContent.new(:url => @feed_url.url, :created_by => current_user.id)
        @meta_description = CGI.unescapeHTML(summary.children[1].text.gsub(/[^\x20-\x7e]/, ''))
        @article.title = @feed_url.title
        @article.sub_type = @article.find_subtype(@article.title)
        @article.description = @meta_description unless @meta_description.blank?
        @article.thumbnail = @images.first if @images.count > 0
      end

      @article_content = @article
      @article.sub_type = "Others" if @article.sub_type.blank?
      @categories.each { |each_cat| @selected_category = each_cat[1] if each_cat[0] == @article.sub_type }
      params[:term] = @article.title
      @results = Product.get_search_items_by_relavance(params)
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

  def process_table_feeds
    @impression_missing = ImpressionMissing.all.first(10)

    @impression_missing.each do |each_record|
      status = 0
      status_val = {"1" => 1, "3" => 2, "4" => 3}
      status_val.default = 0

      status = status_val[each_record.status.to_s] unless each_record.status.blank?
      source = (each_record.hosted_site_url == URI::regexp).blank? ? "" : URI.parse(URI.encode(URI.decode(each_record.hosted_site_url))).host.gsub("www.", "")

      @feed_url = FeedUrl.create(:url => each_record.hosted_site_url, :status => status, :source => source, :category => "Others",
                                 :process_type => "impression_missing")
    end
    redirect_to feeds_path
  end
end
