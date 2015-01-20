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

    title = ""
    unless params[:search].blank?
      title = params[:search][:title]
      begin
        title = eval(title)
      rescue Exception => e
        title = title.to_s.gsub(' ', '%').gsub("'", '%')
      end
    end

    # sort =
    condition = params[:page_loaded_time].blank? ? "1=1" : "created_at < '#{params[:page_loaded_time]}' "
    intial_condition = condition
    unless params[:search].blank?
      #condition = "1=1"
      condition = condition + " and category like '%#{params[:search][:category]}%'" unless params[:search][:category].blank?
      condition = condition + " and status = #{params[:search][:status]}" unless params[:search][:status].blank?
      condition = condition + " and source = '#{params[:search][:source]}'" unless params[:search][:source].blank?
      condition = condition + " and created_at > '#{params[:search][:from_date].to_time}'" unless params[:search][:from_date].blank?
      condition = condition + " and created_at < '#{params[:search][:to_date].to_time}'" unless params[:search][:to_date].blank?
      condition = condition + " and title like '%#{title}%'" unless title.blank?
    end

    if params[:commit] == "Clear"
      condition = intial_condition
      params[:search] = {}
    elsif params[:commit] != "Filter"
      params[:search] ||= {:status => 0}
      condition = condition == intial_condition ? "created_at < '#{params[:page_loaded_time]}' and status = 0" : condition
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


  def feed_urls_batch_update
    params[:page_loaded_time] ||= Time.now.utc
    @loaded_time = params[:page_loaded_time]
    params[:feed_urls_sort_by] ||= "published_at"
    params[:feed_urls_order_by] ||= "desc"

    title = ""
    unless params[:search].blank?
      title = params[:search][:title]
      begin
        title = eval(title)
      rescue Exception => e
        title = title.to_s.gsub(' ', '%')
      end
    end
    # sort =
    condition = params[:page_loaded_time].blank? ? "1=1" : "created_at < '#{params[:page_loaded_time]}' "
    intial_condition = condition
    unless params[:search].blank?
      condition = condition + " and source = '#{params[:search][:source]}'" unless params[:search][:source].blank?
      condition = condition + " and title like '%#{title}%'" unless title.blank?
    end

    condition = condition + " and status = 0"

    if params[:commit] == "Clear"
      condition = intial_condition
      params[:search] = {}
    elsif params[:commit] != "Filter"
      params[:search] ||= {:status => 0}
      condition = condition == intial_condition ? "status = 0" : condition
    end

    @feed_urls = FeedUrl.where(condition).order("#{params[:feed_urls_sort_by]} #{params[:feed_urls_order_by]}").paginate(:page => params[:page], :per_page => 50)
    @new_categories = ["Others"]
    @categories = ArticleCategory.get_by_itemtype(0).map {|x| x[0]}
    @new_categories = (@new_categories << @categories).flatten
    @categories = ([""] << @categories).flatten

    #Assign sources to memcache

    # FeedUrl.check_and_assign_sources_hash_to_cache_from_table()

    # @feed_urls = @feed_urls.paginate(:page => params[:page], :per_page => 25)

    if params[:page]
      return render :partial => "/feeds/feed_url_list_batch_update", :layout => false
    end

    respond_to do |format|
      format.js
      format.html
    end
  end

  def batch_update
    @error = false
    begin
      @feed_urls = FeedUrl.where(:id => params[:feed_urls])
      if params[:commit] == "Mark As Feature"
        @feed_urls.update_all(:status => 2)
      elsif params[:commit] == "Mark As Invalid"
        @feed_urls.update_all(:status => 3)
      elsif params[:commit] == "Default Save"
        @feed_urls.each {|feed_url| feed_url.auto_save_feed_urls(force_default_save=true)}
      elsif params[:commit] == "Save"
        articles_item_id = params[:articles_item_id]
        @feed_urls.each_with_index do |feed_url, index|
          category = params[:article_category]
          category_list = params[:category_list].to_s.split(",")
          category = category_list[index] if category.blank?
          category = "Others" if category.blank?

          updates = {}
          updates.merge!(:article_category => category) unless category.blank?
          updates.merge!(:article_item_ids => articles_item_id) unless articles_item_id.blank?

          feed_url.update_attributes!(updates)
        end
      elsif params[:commit] == "Save And Tag"
        # old_def_val = params[:old_default_values]
        # new_def_val = params[:article_content][:sub_type].to_s + "-" + params[:articles_item_id].to_s
        # def_status = old_def_val == new_def_val
        # feed_url.update_attributes!(:old_default_values => old_def_val, :new_default_values => new_def_val, :default_status => def_status)

        remote_ip = request.remote_ip

        @feed_urls.each_with_index do |feed_url, index|
          category = params[:article_category]
          category_list = params[:category_list].to_s.split(",")
          old_category = category_list[index]
          category = old_category if category.blank?
          category = "Others" if category.blank?

          relevance_product = params[:articles_item_id].to_s.split(",")

          thumbnail = feed_url.images.split(",").first.to_s
          param = { "feed_url_id" => feed_url.id, "default_item_id" => "", "submit_url" => "submit_url",
                    "article_content" => { "itemtype_id" => "", "type" => "ArticleContent", "thumbnail" => thumbnail, "title" => feed_url.title, "url" => feed_url.url,
                                           "sub_type" => category, "description" => feed_url.summary },
                    "share_from_home" => "", "detail" => "", "articles_item_id" => params[:articles_item_id], "external" => "true", "score" => "0", "relevance_product" => relevance_product }

          @through_rss = true
          Resque.enqueue(ArticleContentProcess, "create_article_content", Time.zone.now, param.to_json, current_user.id, remote_ip)
        end
        @feed_urls.update_all(:status => 1, :default_status => 6)
      end
    rescue Exception => e
      @error = true
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
    @actual_title = @feed_url.created_at < 2.weeks.ago ? @feed_url.title : "" unless @feed_url.blank?

    @article_content = ArticleContent.find_by_url(@feed_url.url)

    unless @article_content.blank?
      @already_shared = true
      @feed_url.update_attributes!(:status => 1) rescue ""

      @article_content.check_and_update_mobile_site_feed_urls_from_content(@feed_url, current_user, request.remote_ip)
    else
      @already_shared = false
      @external = true
      @categories = ArticleCategory.get_by_itemtype(0).map {|x| x[0]}

      @feed_url, @article_content, @invalid = ArticleContent.check_and_update_mobile_site_feed_urls_from_feed(@feed_url, current_user, request.remote_ip)

      if @invalid == "true"
        @shared_message = "FeedUrl is Invalid Based on domain name"
        return
      end


      if @feed_url.status == 1 && !@article_content.blank?
        @already_shared = true
        @shared_message = "Shared Automatically from the below url"
      else
        if !@feed_url.blank?
          @article = ArticleContent.new(:url => @feed_url.url, :created_by => current_user.id)
          title_info = @feed_url.title
          if title_info.include?("|")
            title_info = title_info.to_s.slice(0..(title_info.index('|'))).gsub(/\|/, "").strip
          end
          @article.title = title_info
          @article.sub_type = @article.find_subtype(@article.title)
          sub_type, @title_for_search = @feed_url.check_and_update_sub_type(@article)
          @title_for_search = @title_for_search.to_s.gsub("\r\n", "").gsub("\t", "")
          @article.sub_type = sub_type unless sub_type.blank?
          @article.description = @feed_url.summary
          @images = @feed_url.images.split(",")
          @article.thumbnail = @images.first if @images.count > 0
        end

        @article_content = @article
        @article.sub_type = "Others" if @article.sub_type.blank?
        @host_without_www = Item.get_host_without_www(@article.url)
        if @article.sub_type == "Others"
          host = Addressable::URI.parse(@article.url).host
          url = @article.url.gsub(host, "")
          subtype_from_url = @article.find_subtype(url)
          @article.sub_type = subtype_from_url unless subtype_from_url.blank?
        end

        params[:term] = @article.title
      end


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

      #@results = Product.get_search_items_by_relavance(params)
    end

    @search_path = !@feed_url.blank? && @feed_url.category.to_s.split(",").include?("ApartmentType") ? '/search/search_items_by_relavance_housing' : '/search/search_items_by_relavance'

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

  def default_save
    @feed_url = FeedUrl.where("id = ?", params[:feed_url_id]).first
    return_val = @feed_url.auto_save_feed_urls(true)
    status = return_val == "true" ? 1 : 0
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
