require "securerandom"

class ProductsController < ApplicationController
  before_filter :create_impression_before_widgets, :only => [:where_to_buy_items]
  before_filter :create_impression_before_widgets_vendor, :only => [:where_to_buy_items_vendor]
  before_filter :create_impression_before_widget_for_women, :only => [:widget_for_women]
  before_filter :create_impression_before_sports_widget, :only => [:sports_widget]
  before_filter :create_impression_before_elec_widget, :only => [:elec_widget_1]
  before_filter :create_impression_before_price_text_vendor_details, :only => [:price_text_vendor_details]

  # caches_action :where_to_buy_items, :cache_path => @where_to_buy_items_cahce proc {|c|  params[:item_ids].blank? ? params.slice("price_full_details", "path", "sort_disable", "ref_url") : params.slice("price_full_details", "path", "sort_disable", "item_ids") }, :expires_in => 2.hours, :if => proc { |s| params[:is_test] != "true" }
  caches_action :where_to_buy_items, :cache_path => proc {|c|
    if (params[:item_ids].blank? && params[:ref_url].blank?)
      params.slice("price_full_details", "path", "sort_disable", "request_referer")
    elsif params[:item_ids].blank?
      params.slice("price_full_details", "path", "sort_disable", "ref_url")
    else
      params.slice("price_full_details", "path", "sort_disable", "item_ids")
    end
  }, :expires_in => 2.hours, :if => lambda { params[:is_test] != "true" }

  caches_action :elec_widget_1, :cache_path => proc {|c|
    if !params[:item_ids].blank?
      params.slice("item_ids", "page_type", "vendor_ids", "ret_format")
    else
      params.slice("ref_url", "page_type", "vendor_ids", "ret_format")
    end
  }, :expires_in => 2.hours, :if => lambda { params[:is_test] != "true" }

  caches_action :price_text_vendor_details, :cache_path => proc {|c|
    if !params[:item_ids].blank?
      params.slice("item_ids", "page_type")
    else
      params.slice("ref_url", "page_type")
    end
  }, :expires_in => 2.hours, :if => lambda { params[:is_test] != "true" }


  caches_action :where_to_buy_items_vendor, :cache_path => proc {|c|
     if (params[:item_ids].blank? && !params[:ref_url].blank?)
       params.slice("page_type", "path", "price_full_details", "sort_disable", "ref_url", "geo")
     elsif (params[:item_ids].blank? && params[:ref_url].blank?)
      params.slice("page_type", "path", "price_full_details", "sort_disable", "request_referer", "geo")
     elsif !params[:item_ids].blank?
       params.slice("item_ids", "page_type", "path", "price_full_details", "sort_disable", "geo")
     end
   }, :expires_in => 2.hours, :if => lambda { params[:is_test] != "true" }

  caches_action :widget_for_women, :cache_path => proc {|c|
    if params[:beauty] == "true"
      if params[:item_ids].blank?
        params.slice("ref_url", "page_type", "geo", "beauty")
      else
        params.slice("item_ids", "page_type", "geo", "beauty")
      end
    else
      if params[:item_ids].blank?
        params.slice("ref_url", "page_type", "fashion_id", "geo", "beauty")
      else
        params.slice("item_ids", "page_type", "fashion_id", "geo", "beauty")
      end
    end
  }, :expires_in => 2.hours, :if => lambda { params[:is_test] != "true" }

  caches_action :sports_widget, :cache_path => proc {|c|
    if !params[:item_ids].blank?
      params.slice("item_ids", "category_item_detail_id", "page_type", "random_id")
    else
      params.slice("category_item_detail_id", "category_type", "page_type", "random_id")
    end
  }, :expires_in => 2.hours, :if => lambda { params[:is_test] != "true" }


  caches_action :show,  :cache_path => Proc.new { |c|
    if(current_user)
      c.params.merge(user: 1)
    else
      c.params.merge(user: 0)
    end
     }
#  caches_action :search_items, :cache_path => Proc.new { |c| c.params.except(:callback).except(:_) },:expires_in => 24.hours
  before_filter :authenticate_user!, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
  before_filter :get_item_object, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type, :review_it, :add_item_info]
  before_filter :all_user_follow_item, :if => Proc.new { |c| !current_user.blank? }, :except => [:where_to_buy_items, :where_to_buy_items_vendor, :sports_widget, :elec_widget_1, :price_text_vendor_details, :widget_for_women]
  before_filter :store_location, :only => [:show]
  before_filter :set_referer,:only => [:show]
  before_filter :log_impression, :only=> [:show]
  skip_before_filter :cache_follow_items, :store_session_url, :only => [:where_to_buy_items, :where_to_buy_items_vendor, :sports_widget, :elec_widget_1, :price_text_vendor_details, :widget_for_women]
  layout 'product'
  include FollowMethods
  include ItemsHelper
  include Admin::AdvertisementsHelper
#  layout false, only: [:where_to_buy_items]

 def log_impression
   @item = Item.find(params[:id]) rescue nil
   @item.impressions.create(ip_address: request.remote_ip,user_id:(current_user.id rescue '')) unless @item.blank?
 end
  def set_referer
    @item = Item.find(params[:id]) rescue nil
    unless request.referer.nil?
      if request.referer.include?("google")   
        session[:product_warning_message] = "true"  
        session[:http_referer] = request.referer
        session[:referer_counter] = 1
        return true
      end
   end
 

     if (session[:referer_counter] == 1)  &&  request.env["HTTP_X_REQUESTED_WITH"] != "XMLHttpRequest"
       session[:referer_counter]+= 1
       return true
   end
 end

  def index
    @static_page1  = "true"
    @no_custom = "true" 
    @filter_by = params["fl"]
    search_type = request.path.split("/").last
    @type = search_type.singularize.camelize.constantize
    session[:itemtype] = @type
    session[:warning] = "true" 
    @itemtype = Itemtype.find_by_itemtype(@type)
    @popular_topics = Item.popular_topics(@type)
    @article_categories = ArticleCategory.get_by_itemtype(@itemtype.id) #ArticleCategory.by_itemtype_id(@itemtype.id)#.map { |e|[e.name, e.id]  }
    @followers =  User.get_followers(search_type)
    count = @followers.length
    if count < 20
      @followers_count = count
    else
      @followers_count = User.get_followers_count(search_type) 
    end    
    @top_contributors =  User.get_top_contributors
    #@article_categories = ArticleCategory.get_by_itemtype(0)
 end

  def specification
    @item = Item.find(params[:id])
  end

  def topics
    @type = params[:type].capitalize
    @itemtype = Itemtype.find_by_itemtype(@type)
    @topic_cloud_hash = Topic.topic_clouds(@itemtype)
  end

  def ratings
   # @contents = ArticleContent.find_by_sql("select * from article_contents ac inner join contents c on c.id = ac.id inner join item_contents_relations_cache icc on icc.content_id = ac.id left outer join facebook_counts fc on fc.content_id = ac.id where icc.item_id = #{params[:id]} and c.sub_type = 'Reviews' and c.status = 1  order by (if(total_votes is null,0,total_votes) + like_count + share_count) desc" )
      respond_to do |format|
        format.json{render json: @contents}
      end
    
  end
  
  def show
    @static_page1  = "true"
    @filter_by = params["fl"]
    @write_review = params[:type]
    session[:warning] = "true"
    Vote.get_vote_list(current_user) if user_signed_in? 
    #session[:product_warning_message] = "true"
    @item = Item.includes([:itemdetails => :vendor],[:attribute_values], :itemrelationships, :item_rating).find(params[:id])#where(:id => params[:id]).includes(:item_attributes).first
    # @pro_cons = ItemProCon.find_by_sql("select *, count(*) as count from item_pro_cons
    #     where item_id = #{@item.id} and pro_con_category_id is not null group by pro_con_category_id, proorcon
    #     union
    #     select *, 1 as count from item_pro_cons
    #     where item_id = #{@item.id} and pro_con_category_id is null
    #     order by count desc, (case when pro_con_category_id is null then 99999 else pro_con_category_id end) asc, letters_count desc, `index`
    #     ")
    # @pro_cons = @pro_cons.group_by(&:proorcon)
    # @verdicts = ArticleContent.find_by_sql("select ac.* from article_contents ac inner join contents c on c.id = ac.id inner join item_contents_relations_cache icc on icc.content_id = ac.id left outer join facebook_counts fc on fc.content_id = ac.id where icc.item_id = #{@item.id} and c.sub_type = 'Reviews' and ac.field4 is not null and trim(ac.field4) != '' and ac.video is null and c.status = 1  order by (if(total_votes is null,0,total_votes) + like_count + share_count) desc limit 6" )
    @new_version_item = Item.find(@item.new_version_item_id) if (@item.new_version_item_id && @item.new_version_item_id != 0)
    if !current_user
      @custom = "true"
    end 
    @no_custom = "true" if @item.type == "Topic" 
    session[:itemtype] = @item.get_base_itemtype
    @where_to_buy_items = @item.itemdetails.where("status = 1 and isError = 0").order('sort_priority desc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
    # @attribute_degree_view = @attribute_degree_view = @item.attribute_values.collect{|ia| ia if ia.attribute_id == 294}.compact.first.value rescue ""
    
    if (@item.is_a? Product)
      @related_items = Item.get_related_items(@item, 3, true) 
    end
    @invitation=Invitation.new(:item_id => @item, :item_type => @item.itemtype)
    user_follow_type(@item, current_user)
    #@tip = Tip.new
    #@contents = Tip.order('created_at desc').limit(5)
    @review = ReviewContent.new
    @article_content=ArticleContent.new(:itemtype_id => @item.itemtype_id)
    session[:invitation] = ""
    @itemtype = @item.itemtype
    #@questions = QuestionContent.all

    # if (@item.is_a? Product)
    #   @article_categories = ArticleCategory.get_by_itemtype(@item.itemtype_id)
    #  # @article_categories = ArticleCategory.by_itemtype_id(@item.itemtype_id).map { |e|[e.name, e.id]  }
    # else
    #   @article_categories = ArticleCategory.get_by_itemtype(0)
    #  # @article_categories = ArticleCategory.by_itemtype_id(0).map { |e|[e.name, e.id]  }
    # end

    if((@item.is_a? Product) &&  (!@item.manu.nil?))
      @dealer_locators =  DealerLocator.find_by_item_id(@item.manu.id)
    end 

    # @top_contributors = @item.get_top_contributors
    @related_items = Item.get_related_item_list(@item.id, 10) if @item.can_display_related_item?
    @no_popup_background = "true"
    @item_specification_summary_lists = @item.attribute_values.includes(:attribute => :item_specification_summary_lists).where("attribute_values.item_id=? and item_specification_summary_lists.itemtype_id =?", @item.id, @item.itemtype_id).order("item_specification_summary_lists.sortorder ASC").group_by(&:proorcon)
    @item_specification_summary_lists.delete("nothing")
    @items_specification = {"Pro" => [], "Con" => []}
    @item_specification_summary_lists.each do |key, value|
      @items_specification[key[:key]] << {:values => value, description: key[:description],title: key[:title]} if key
    end

  end

  def related_items
    @related_items = Item.get_related_item_list(params[:item_id], 10, params[:page])
  end

  def related_products
    @item = Item.where(:id => params[:id]).first
    @follow_type = params[:follow_type]
    respond_to do |format|
      format.js { render :partial=> 'itemrelationships/relateditem', :collection => @item.unfollowing_related_items(current_user, 2) }
    end

  end
  
  
  def external_page
    cookies[:plan_to_temp_user_id] = { value: SecureRandom.hex(20), expires: 1.year.from_now } if cookies[:plan_to_temp_user_id].blank?
    @item = Item.find(params[:item_id])
    @showspec = params[:show_spec].blank? ? 0 : params[:show_spec] 
    @showcompare = params[:show_compare].blank? ? 1 : params[:show_compare]
    @showreviews = params[:show_reviews].blank? ? 0 : params[:show_reviews]
    @defaulttab = params[:at].blank? ? "compare_price" : params[:at]
    @impression_id = params[:iid]
    @req = request.referer  
    @where_to_buy_items = @item.itemdetails.includes(:vendor).where("status = 1 and isError = 0").order('sort_priority desc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
    # @impression_id = AddImpression.save_add_impression_data("pricecomparision",@item.id,request.referer,Time.zone.now,current_user,request.remote_ip,@impression_id,cookies[:plan_to_temp_user_id],nil)

    # @impression_id = SecureRandom.uuid
    # impression_params =  {:imp_id => @impression_id, :type => "pricecomparision", :itemid => @item.id, :request_referer => request.referer, :time => Time.zone.now, :user => current_user.blank? ? nil : current_user.id, :remote_ip => request.remote_ip, :impression_id => @impression_id, :itemaccess => nil,
    #                       :params => nil, :temp_user_id => cookies[:plan_to_temp_user_id], :ad_id => nil}.to_json

    @impression_id = nil
    impression_params =  {:imp_id => @impression_id, :type => "pricecomparision", :itemid => @item.id, :request_referer => request.referer, :time => Time.zone.now, :user => current_user.blank? ? nil : current_user, :remote_ip => request.remote_ip, :impression_id => @impression_id, :itemaccess => nil,
                          :params => nil, :temp_user_id => cookies[:plan_to_temp_user_id], :ad_id => nil}

    # Resque.enqueue(CreateImpressionAndClick, 'AddImpression', impression_params)
    @impression_id = AddImpression.add_impression_to_resque(impression_params[:type], impression_params[:item_id], impression_params[:request_referer], impression_params[:user], impression_params[:remote_ip], impression_params[:impression_id], impression_params[:itemaccess], impression_params[:params], impression_params[:temp_user_id], impression_params[:ad_id], nil)

    if @showspec == 1
      @item_specification_summary_lists = @item.attribute_values.includes(:attribute => :item_specification_summary_lists).where("attribute_values.item_id=? and item_specification_summary_lists.itemtype_id =?", @item.id, @item.itemtype_id).order("item_specification_summary_lists.sortorder ASC").group_by(&:proorcon)
      # @contents = Content.where(:sub_type => "Reviews")
      @item_specification_summary_lists.delete("nothing")
      @items_specification = {"Pro" => [], "Con" => []}
      @item_specification_summary_lists.each do |key, value|
      @items_specification[key[:key]] << {:values => value, description: key[:description],title: key[:title]} if key
      end
    end
    render :layout => false
  end
  
  def review_it
  end

  def add_item_info
  end

  def follow_buttons
   unless (current_user.nil?)
    if !params[:item_id].blank?
      @item = Item.find(params[:item_id])
    elsif !params[:items_id].blank?
      @items = Item.where("id in (?)", params[:items_id].split(","))
    end     
   end
  end

  def is_number?
    true if Float(self) rescue false
  end

   def where_to_buy_items
    url_params, url, itemsaccess, item_ids = check_and_assigns_widget_default_values()
    @test_condition = @is_test == "true" ? "&is_test=true" : ""
    @items, itemsaccess, url, tempurl = Item.get_items_by_item_ids(item_ids, url, itemsaccess, request, true, params[:sort_disable])

    # include pre order status if we show more details.
    unless @items.blank?
      status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
      @publisher = Publisher.getpublisherfromdomain(url) if @publisher.blank?
      # Check have to activate tabs for publisher or not
      @activate_tab = true if (@publisher.blank? || (!@publisher.blank? && @active_tabs_for_publisher.include?(@publisher.id)))

      # Update Items if there is only one item
      @items = Item.get_related_items_if_one_item(@items, @publisher, status) if (@activate_tab && @items.count == 1 && params[:sort_disable] != "true")

      @where_to_buy_items, @item, @best_deals, @impression_id = Itemdetail.get_where_to_buy_items(@publisher, @items, @show_price, status, url, current_user, request.remote_ip,
                                                                                  itemsaccess, url_params, cookies[:plan_to_temp_user_id], @is_test, nil)
      @show_count = Item.get_show_item_count(@items)

      responses = []
      @where_to_buy_items.group_by(&:site).each do |site, items|
        items.each_with_index do |item, index|
          display_item_details(item)
          if index == 0
            responses << {image_url: item.image_url, display_price: display_price_detail(item), history_detail: "/history_details?detail_id=#{item.item_details_id}"}
          end
        end
      end
    else
      @where_to_buy_items =[]
      itemsaccess = "none"
      @impression = ImpressionMissing.create_or_update_impression_missing(tempurl)
    end
    @ref_url = url
    jsonp = prepare_response_json()
    render :text => jsonp, :content_type => "text/javascript"
   end

  def where_to_buy_items_vendor
    # params[:item_ids] = "13874" if params[:item_ids].blank?
    params[:page_type] ||= "type_1" if params[:page_type].blank?
    url_params, url, itemsaccess, item_ids = check_and_assigns_widget_default_values()
    @test_condition = @is_test == "true" ? "&is_test=true" : ""

    @items, tempurl, from_article_field = Item.get_items_from_url(url, params[:item_ids])
    url =  tempurl

    if !@items.blank?
      @item, @items, @search_url, @extra_items = Item.get_item_items_from_amazon(@items, params[:item_ids], params[:page_type], params[:geo])

      if @items.blank?
        @item, @items, @search_url, @extra_items = Item.get_best_seller_beauty_items_from_amazon(params[:page_type], url, params[:geo])
      end
    else
      @item, @items, @search_url, @extra_items = Item.get_best_seller_beauty_items_from_amazon(params[:page_type], url, params[:geo])
      @impression = ImpressionMissing.create_or_update_impression_missing(tempurl, "fashion")
    end

    @search_url = CGI.escape(@search_url)

    # include pre order status if we show more details.
    unless @items.blank?
      status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
      @publisher = Publisher.getpublisherfromdomain(url)
      # Check have to activate tabs for publisher or not
      @activate_tab = true if (@publisher.blank? || (!@publisher.blank? && @active_tabs_for_publisher.include?(@publisher.id)))

      @where_to_buy_items = []

      if @is_test != "true"
        @impression_id = AddImpression.add_impression_to_resque("fashion", @item.id, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], nil, nil, nil)
      end

      @show_count = Item.get_show_item_count(@items)

      responses = []
      @where_to_buy_items = [@items]
      @where_to_buy_items.each do |items|
        items.each_with_index do |item, index|
          if index == 0
            responses << {image_url: item.image_url, display_price: 100, history_detail: "/history_details?detail_id=#{item.id}"}
          end
        end
      end
    else
      @where_to_buy_items =[]
      itemsaccess = "none"
      @impression = ImpressionMissing.create_or_update_impression_missing(tempurl, "fashion")
    end
    @ref_url = url
    jsonp = prepare_response_json()

    headers["Content-Type"] = "text/javascript; charset=utf-8"
    respond_to do |format|
      format.js { render :text => jsonp, :content_type => "text/javascript" }
    end
      
    # render :layout => false
  end

  def widget_for_women
    # params[:item_ids] = "13874" if params[:item_ids].blank?
    params[:page_type] ||= "type_1" if params[:page_type].blank?
    url_params, url, itemsaccess, item_ids = check_and_assigns_widget_default_values()
    @test_condition = @is_test == "true" ? "&is_test=true" : ""
    url =  @url

    included_beauty = @items.map {|d| d.is_a?(Beauty)}.include?(true) rescue false
    if url.include?("bebeautiful.in")
      show_widget_for_bebeautiful(url, itemsaccess)
    elsif included_beauty
      get_details_from_beauty_items(url, itemsaccess)
    else
      get_details_from_fashion_ads()
    end
    jsonp = prepare_response_json()

    headers["Content-Type"] = "text/javascript; charset=utf-8"
    respond_to do |format|
      format.js { render :text => jsonp, :content_type => "text/javascript" }
    end

    # render :layout => false
  end

  def get_details_from_beauty_items(url, itemsaccess)
    if !@items.blank?
      @item, @items, @search_url, @extra_items = Item.get_item_items_from_amazon(@items, params[:item_ids], params[:page_type], params[:geo])

      if @items.blank?
        @item, @items, @search_url, @extra_items = Item.get_best_seller_beauty_items_from_amazon(params[:page_type], url, params[:geo])
      end
    else
      @item, @items, @search_url, @extra_items = Item.get_best_seller_beauty_items_from_amazon(params[:page_type], url, params[:geo])
      @impression = ImpressionMissing.create_or_update_impression_missing(url, "fashion")
    end

    @search_url = CGI.escape(@search_url)
    url_params = Advertisement.make_url_params(params)

    # include pre order status if we show more details.
    unless @items.blank?
      status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
      @publisher = Publisher.getpublisherfromdomain(url)
      # Check have to activate tabs for publisher or not
      # @activate_tab = true if (@publisher.blank? || (!@publisher.blank? && @active_tabs_for_publisher.include?(@publisher.id)))
      if @is_test != "true"
        @impression_id = AddImpression.add_impression_to_resque("fashion", @item.id, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], nil, nil, nil)
      end

      @show_count = Item.get_show_item_count(@items)
    else
      @where_to_buy_items =[]
      itemsaccess = "none"
      @impression = ImpressionMissing.create_or_update_impression_missing(url, "fashion")
    end
    @ref_url = url
  end

  def show_widget_for_bebeautiful(url, itemsaccess)
    valid_item_names = ["pond's","ponds", "lakme", "sunslik", "dove", "vaseline", "tresemme","aviance","axe ","breeze","clinic plus","close up","elle 18","fair and lovely","fair & lovely","hamam","ayush","liril","lux ","pears","pepsodent","rexona","rin ","surf excel","vim "]

    if !@items.blank?
      is_multi_array = @items.first.is_a?(Array)

      if is_multi_array
        multi_items = @items
        multi_items.each_with_index do |each_items, index|
          if index == 0
            @item, items, @search_url, @extra_items = Item.get_item_items_from_amazon(each_items, params[:item_ids], params[:page_type], params[:geo], valid_item_names)
            @items = []
            @items << items
          else
            new_item, new_items, new_search_url, new_extra_items = Item.get_item_items_from_amazon(each_items, params[:item_ids], params[:page_type], params[:geo], valid_item_names)
            @items << new_items
          end

          break if @items.flatten.count >= 4
        end
        @items = @items.flatten
      else
        @item, @items, @search_url, @extra_items = Item.get_item_items_from_amazon(@items, params[:item_ids], params[:page_type], params[:geo], valid_item_names)
      end

      if @items.blank? || @items.count < 4
        total_items = @items
        @item, @items, @search_url, @extra_items = Item.get_best_seller_beauty_items_from_amazon(params[:page_type], url, params[:geo], valid_item_names)

        @items = total_items + @items
        @items = @items.flatten
      end
    else
      @item, @items, @search_url, @extra_items = Item.get_best_seller_beauty_items_from_amazon(params[:page_type], url, params[:geo], valid_item_names)
      @impression = ImpressionMissing.create_or_update_impression_missing(url, "fashion")
    end

    @items = @items.uniq

    @search_url = CGI.escape(@search_url)
    url_params = Advertisement.make_url_params(params)

    # include pre order status if we show more details.
    unless @items.blank?
      status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
      @publisher = Publisher.getpublisherfromdomain(url)
      # Check have to activate tabs for publisher or not
      # @activate_tab = true if (@publisher.blank? || (!@publisher.blank? && @active_tabs_for_publisher.include?(@publisher.id)))
      if @is_test != "true"
        @impression_id = AddImpression.add_impression_to_resque("fashion", @item.id, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], nil, nil, nil)
      end

      @show_count = Item.get_show_item_count(@items)
    else
      @where_to_buy_items =[]
      itemsaccess = "none"
      @impression = ImpressionMissing.create_or_update_impression_missing(url, "fashion")
    end
    @ref_url = url
  end

  def get_details_from_fashion_ads()
    p_item_ids = item_ids = []
    p_item_ids = item_ids = params[:item_ids].to_s.split(",") unless params[:item_ids].blank?

    impression_type, url, url_params, itemsaccess, vendor_ids, ad_id, winning_price_enc = check_and_assigns_ad_default_values()

    # static ad process
    # @publisher = Publisher.getpublisherfromdomain(@ad.click_url)

    @ad_template_type = "type_1" #TODO: only accept type 1

    # @vendor = Vendor.where(:name => "Amazon").first
    # vendor_ids = [@vendor.id]
    # @vendor_image_url = configatron.root_image_url + "vendor/medium/default_vendor.jpeg"
    # @vendor_ad_details = VendorDetail.get_vendor_ad_details([9882])

    # @current_vendor = @vendor_ad_details[9882]
    # @current_vendor = {} if @current_vendor.blank?
    # item_ids = item_id.to_s.split(",")

    @item, @item_details = Item.get_item_and_item_details_from_fashion_url(url, item_ids, vendor_ids, params[:fashion_id])
    # @sliced_item_details = @item_details.each_slice(2)

    @items = Itemdetail.get_widget_details_from_itemdetails(@item_details)

    item_id = @item.id rescue nil
    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque("fashion", item_id, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                              cookies[:plan_to_temp_user_id], nil, nil, nil)
    end

    # respond_to do |format|
    #   format.json {
    #     return render :json => {:success => true, :html => render_to_string("advertisements/show_fashion_ads.html.erb", :layout => false)}, :callback => params[:callback]
    #   }
    #   format.html { return render "show_fashion_ads.html.erb", :layout => false }
    # end
  end

  def elec_widget_1
    url_params, url, itemsaccess, item_ids = check_and_assigns_widget_default_values()
    @test_condition = @is_test == "true" ? "&is_test=true" : ""
    @items, itemsaccess, url, tempurl = Item.get_items_by_item_ids(item_ids, url, itemsaccess, request, true, params[:sort_disable])
    @where_to_buy_items = []
    if params[:vendor_ids].blank?
      #defaulting to amazon.
      vendor_ids = '9882'.to_s.split(",");
    else
      vendor_ids = params[:vendor_ids].to_s.split(",")
    end

    show_count = params[:page_type] == "type_1" ? 6 : 4
    show_count = 10 if params[:ret_format] == "xml"

    @multiple_vendors = false

    # include pre order status if we show more details.
    unless @items.blank?
      status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
      @publisher = Publisher.getpublisherfromdomain(url)
      # Check have to activate tabs for publisher or not
      @activate_tab = true if (@publisher.blank? || (!@publisher.blank? && @active_tabs_for_publisher.include?(@publisher.id)))
      @item = @items.first

      @where_to_buy_items = Itemdetail.get_where_to_buy_items_using_vendor(@publisher, @items, @show_price, status, [], vendor_ids)
      @where_to_buy_items.map {|each_item| each_item.match_type = "exact" if each_item.match_type.blank? }

      # Update Items if there is only one item
      if @where_to_buy_items.count < show_count
        itemsaccess = "related_items"
        items = Item.get_related_items_if_one_item(@items, @publisher, status)

        related_items = items - @items
        @item = items.first if @item.blank?

        @where_to_buy_items = Itemdetail.get_where_to_buy_items_using_vendor(@publisher, related_items, @show_price, status, @where_to_buy_items, vendor_ids)
        @where_to_buy_items.map {|each_item| each_item.match_type = "related" if each_item.match_type.blank? }
      end
    end

    if @where_to_buy_items.blank? || (!@where_to_buy_items.blank? && @where_to_buy_items.count < show_count)
      # item_ids = configatron.amazon_top_mobiles.to_s.split(",")
      item_ids = $redis.get("amazon_top_mobiles").to_s.split(",")
      first_six_items = item_ids.shuffle.first(6)
      @items = Item.where(:id => first_six_items)
      @item = @items.first
      @publisher = Publisher.getpublisherfromdomain(url)
      status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
      itemaccess = "popular_items"
      @where_to_buy_items = Itemdetail.get_where_to_buy_items_using_vendor(@publisher, @items, @show_price, status, @where_to_buy_items, vendor_ids)
      @where_to_buy_items.map {|each_item| each_item.match_type = "top" if each_item.match_type.blank? }
      @impression = ImpressionMissing.create_or_update_impression_missing(tempurl)
    end

    @where_to_buy_items = @where_to_buy_items.first(show_count)

    if @where_to_buy_items.blank?
      itemsaccess = "none"
      @impression = ImpressionMissing.create_or_update_impression_missing(tempurl)
    else
      if params[:is_test] != "true"
        @impression_id = AddImpression.add_impression_to_resque("elec_widget_1", @item, url, current_user.blank? ? nil : current_user.id, request.remote_ip, nil, itemsaccess, url_params,
                                                               cookies[:plan_to_temp_user_id], nil, nil, nil)
      end
    end

    if !vendor_ids.blank?
      @vendor_ad_details = VendorDetail.get_vendor_ad_details(vendor_ids)
      @multiple_vendors = true if vendor_ids.count > 1
      @vendor = Vendor.where(:id => vendor_ids).first
    end
    @vendor_detail = @vendor.vendor_detail rescue VendorDetail.new

    @ref_url = url

    if params[:ret_format] == "html"
      return render "elec_widget_1.js.erb", :layout => false, :content_type => "text/html"
    elsif params[:ret_format] == "xml" # For xml request
      return render "elec_widget_1.xml.builder", :layout => false, :content_type => "text/xml"
    else
      jsonp = prepare_response_json()
      return render :text => jsonp, :content_type => "text/javascript"
    end
  end

  def price_vendor_details
    # params[:item_ids] = "13874" if params[:item_ids].blank?
    params[:page_type] ||= "type_1" if params[:page_type].blank?
    url_params, url, itemsaccess, item_ids = check_and_assigns_widget_default_values()
    @test_condition = @is_test == "true" ? "&is_test=true" : ""

    if params[:page_type] == "type_2"
      return price_widget_type_2(url, itemsaccess, url_params, item_ids)
    end

    tempurl = "" #TODO: Hot coded values
    @price_text = Item.get_amazon_item_from_item_id(params[:item_ids])
    url =  tempurl

    # include pre order status if we show more details.
    unless @price_text.blank?
      status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
      # @publisher = Publisher.getpublisherfromdomain(url)
      @publisher = nil
      # Check have to activate tabs for publisher or not
      @activate_tab = true if (@publisher.blank? || (!@publisher.blank? && @active_tabs_for_publisher.include?(@publisher.id)))

      @where_to_buy_items = []

      if @is_test != "true"
        @impression_id = AddImpression.add_impression_to_resque("amazon_widget", params[:item_ids], url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], nil, nil, nil)
      end

      # @show_count = Item.get_show_item_count(@items)

      responses = []
      @where_to_buy_items = []
    else
      @where_to_buy_items =[]
      itemsaccess = "none"
      @impression = ImpressionMissing.create_or_update_impression_missing(tempurl, "amazon_widget")
    end
    @ref_url = url
    jsonp = prepare_response_json()

    headers["Content-Type"] = "text/javascript; charset=utf-8"
    respond_to do |format|
      format.js { render :text => jsonp, :content_type => "text/javascript" }
    end

    # render :layout => false
  end

  def book_price_widget
    # params[:item_ids] = "13874" if params[:item_ids].blank?
    params[:page_type] ||= "type_1" if params[:page_type].blank?
    @ad_template_type ||= params[:page_type]
    url_params, url, itemsaccess, item_ids = check_and_assigns_widget_default_values()
    @test_condition = @is_test == "true" ? "&is_test=true" : ""

    tempurl = "" #TODO: Hot coded values
    @item = Item.get_amazon_book_item_from_isbn(params[:item_ids])
    url =  tempurl

    @vendor_ad_details = VendorDetail.get_vendor_ad_details([9882])

    # include pre order status if we show more details.
    unless @item.blank?
      status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
      # @publisher = Publisher.getpublisherfromdomain(url)
      @publisher = nil
      # Check have to activate tabs for publisher or not
      @activate_tab = true if (@publisher.blank? || (!@publisher.blank? && @active_tabs_for_publisher.include?(@publisher.id)))

      @where_to_buy_items = []

      if @is_test != "true"
        @impression_id = AddImpression.add_impression_to_resque("book_price_widget", params[:item_ids], url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], nil, nil, nil)
      end

      # @show_count = Item.get_show_item_count(@items)

      responses = []
      @where_to_buy_items = []
    else
      @where_to_buy_items =[]
      itemsaccess = "none"
      @impression = ImpressionMissing.create_or_update_impression_missing(tempurl, "book_price_widget")
    end

    @ref_url = url
    jsonp = prepare_response_json()

    headers["Content-Type"] = "text/javascript; charset=utf-8"
    respond_to do |format|
      format.js { render :text => jsonp, :content_type => "text/javascript" }
    end
  end

  def get_price_from_vendor
    @price_text = Item.get_amazon_item_from_item_id(params[:item_id]) rescue ""

    headers["Content-Type"] = "text/javascript; charset=utf-8"
    respond_to do |format|
      format.js { render :text => @price_text, :content_type => "text/javascript" }
      format.html { render :text => @price_text }
    end
  end

  def price_text_vendor_details
    # params[:item_ids] = "13874" if params[:item_ids].blank?
    params[:page_type] ||= "type_1" if params[:page_type].blank?
    url_params, url, itemsaccess, item_ids = check_and_assigns_widget_default_values()
    @test_condition = @is_test == "true" ? "&is_test=true" : ""
    tempurl = url

    @publisher = Publisher.getpublisherfromdomain(url)
    @itemdetail = Item.get_price_text_from_url(url, @publisher, params[:page_type])
    @vendor_ad_details = VendorDetail.get_vendor_ad_details([9882])

    if params[:page_type] == "type_3" || params[:page_type] == "type_4"
      return price_widget_type_3(url, itemsaccess, url_params)
    end

    # include pre order status if we show more details.
    unless @itemdetail.blank?
      status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
      # Check have to activate tabs for publisher or not
      @activate_tab = true if (@publisher.blank? || (!@publisher.blank? && @active_tabs_for_publisher.include?(@publisher.id)))

      @where_to_buy_items = []

      if @is_test != "true"
        @impression_id = AddImpression.add_impression_to_resque("price_text_widget", params[:item_ids], url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], nil, nil, nil)
      end

      # @show_count = Item.get_show_item_count(@items)

      responses = []
      @where_to_buy_items = []
    else
      @where_to_buy_items =[]
      itemsaccess = "none"
      @impression = ImpressionMissing.create_or_update_impression_missing(tempurl, "price_text_widget")
    end
    @ref_url = url
    jsonp = prepare_response_json()

    headers["Content-Type"] = "text/javascript; charset=utf-8"
    respond_to do |format|
      format.js { render :text => jsonp, :content_type => "text/javascript" }
    end

    # render :layout => false
  end

  def sports_widget
    # params[:item_ids] = "13874" if params[:item_ids].blank?
    params[:page_type] ||= "type_1" if params[:page_type].blank?
    url_params, url, itemsaccess, item_ids = check_and_assigns_widget_default_values()

    # if params[:page_type] == "type_1"
    #   @category_item_detail = Item.get_amazon_product_text_link(url, params[:page_type])
    #   if @category_item_detail.item_type == "product links"
    #     @category_item_detail = Item.get_amazon_product_product_text_link_from_item_id(@category_item_detail.text, params[:page_type])
    #   end
    # else
    #   @category_item_detail = Item.get_amazon_product_text_link_from_item_id(url, params[:page_type])
    # end
    @category_item_details = []

    if (params[:page_type] == "type_4" || params[:page_type] == "type_6")
        return deal_item_process(url, itemsaccess, url_params)
    elsif params[:page_type] == "type_5"
      return price_widget_type_2(url, itemsaccess, url_params, item_ids)
    end

    @category_item_detail = Item.get_amazon_product_text_link(url, params[:page_type], params[:category_item_detail_id])
    if !@category_item_detail.blank? && @category_item_detail.item_type == "product links"
      @category_item_detail_id = @category_item_detail.id
      params[:category_item_detail_id] = @category_item_detail_id
      @category_item_detail = Item.get_amazon_product_product_text_link_from_item_id(@category_item_detail.text, params[:page_type])
    elsif !@category_item_detail.blank? && @category_item_detail.item_type == "keyword links"
      @category_item_detail_id = @category_item_detail.id
      params[:category_item_detail_id] = @category_item_detail_id
      @category_item_details = Item.get_amazon_products_from_keyword(@category_item_detail.text)

      # @category_item_details << OpenStruct.new(:title => "ihave ia1310 Boss 10000mAH Power Bank (Gold)", :sale_price => "Rs 1,308.00", :percentage_saved => nil, :click_url => "http://www.amazon.in/ihave-ia1310-Boss-10000mAH-Power/dp/B00N9OVW0G%3FSubscriptionId%3DAKIAJWDCN4DJWNL2FK5A%26tag%3Dpla04-21%26linkCode%3Dxm2%26camp%3D2025%26creative%3D165953%26creativeASIN%3DB00N9OVW0G")
     end

    # include pre order status if we show more details.
    unless @category_item_detail.blank?
      status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
      # @publisher = Publisher.getpublisherfromdomain(url)
      @publisher = nil
      # Check have to activate tabs for publisher or not
      @activate_tab = true if (@publisher.blank? || (!@publisher.blank? && @active_tabs_for_publisher.include?(@publisher.id)))

      @where_to_buy_items = []

      if @is_test != "true"
        @impression_id = AddImpression.add_impression_to_resque("amazon_sports_widget", @category_item_detail_id, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], nil, nil, nil)
      end

      @click_url = configatron.hostname + history_details_path(:ads_id => nil, :iid => @impression_id, :red_sports_url => @category_item_detail.link, :item_id => @category_item_detail_id, :ref_url => params[:ref_url])

      # @show_count = Item.get_show_item_count(@items)

      responses = []
      @where_to_buy_items = []
    else
      @where_to_buy_items =[]
      itemsaccess = "none"
      @impression = ImpressionMissing.create_or_update_impression_missing(url, "amazon_sports_widget")
    end
    @ref_url = url
    jsonp = prepare_response_json()



    headers["Content-Type"] = "text/javascript; charset=utf-8"
    respond_to do |format|
      format.js { render :text => jsonp, :content_type => "text/javascript" }
    end
    # render :layout => false
  end

  def deal_item_process(url, itemsaccess, url_params)
    @item_details = @items = DealItem.get_deal_item_based_on_hour(params[:random_id], for_widget="true")
    return_path = "products/deal_widget.html.erb"

    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque("amazon_sports_widget", @items.first.id, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                              cookies[:plan_to_temp_user_id], nil, nil, nil)
    end

    if params[:page_type] == "type_6"
      @suitable_ui_size = "300_250"
      @vendor_ad_details = VendorDetail.get_vendor_ad_details([9882])
      return_path = "products/deal_widget_type_6.html.erb"
    end

    respond_to do |format|
      format.json {
        return render :json => {:success => true, :html => render_to_string(return_path, :layout => false)}, :callback => params[:callback]
      }
      format.html { return render return_path, :layout => false }
      format.js {
        return render :json => {:success => true, :html => render_to_string(return_path, :layout => false)}, :callback => params[:callback]
      }
    end
  end

  def price_widget_type_2(url, itemsaccess, url_params, item_ids)
    keyword = item_ids[0]
    @amazon_item = keyword.blank? ? OpenStruct.new : Item.get_amazon_product_link_from_asin(keyword)

    if @amazon_item.asin.to_s == item_ids.first
      # if item_ids.include?("B00AXWKTR4")
      #   click_url = "http://www.firstcry.com/huggies/huggies-new-born-taped-diapers-for-the-new-baby-24-pieces/435222/product-detail?sterm=Huggies%20Newborn%20Diapers&spos=1"
      # end
      # @first_cry_item = Item.get_first_cry_item(click_url)

      if @is_test != "true"
        @impression_id = AddImpression.add_impression_to_resque("amazon_sports_widget", nil, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], nil, nil, nil)
      end

      @amazon_click_url = configatron.hostname + history_details_path(:ads_id => nil, :iid => @impression_id, :red_sports_url => @amazon_item.link, :item_id => nil, :ref_url => params[:ref_url])
     # @fc_click_url = configatron.hostname + history_details_path(:ads_id => nil, :iid => @impression_id, :red_sports_url => click_url, :item_id => nil, :ref_url => params[:ref_url])
    end

    respond_to do |format|
      format.json {
        return render :json => {:success => true, :html => render_to_string("products/price_widget_type_2.html.erb", :layout => false)}, :callback => params[:callback]
      }
      format.html { return render "price_widget_type_2.html.erb", :layout => false }
      format.js {
        return render :json => {:success => true, :html => render_to_string("products/price_widget_type_2.html.erb", :layout => false)}, :callback => params[:callback]
      }
    end
  end

  def price_widget_type_3(url, itemsaccess, url_params)
    if !@itemdetail.blank?
      # if item_ids.include?("B00AXWKTR4")
      #   click_url = "http://www.firstcry.com/huggies/huggies-new-born-taped-diapers-for-the-new-baby-24-pieces/435222/product-detail?sterm=Huggies%20Newborn%20Diapers&spos=1"
      # end
      # @first_cry_item = Item.get_first_cry_item(click_url)

      if @is_test != "true"
        @impression_id = AddImpression.add_impression_to_resque("amazon_price_widget", nil, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], nil, nil, nil)
      end

      @amazon_click_url = configatron.hostname + history_details_path(:ads_id => nil, :iid => @impression_id, :red_sports_url => @itemdetail.url, :item_id => nil, :ref_url => params[:ref_url])
      # @fc_click_url = configatron.hostname + history_details_path(:ads_id => nil, :iid => @impression_id, :red_sports_url => click_url, :item_id => nil, :ref_url => params[:ref_url])
    end

    return_url = "products/price_widget_type_3.html.erb"

    if params[:page_type] == "type_4"
      return_url = "products/price_widget_type_4.html.erb"
    end

    respond_to do |format|
      format.json {
        return render :json => {:success => true, :html => render_to_string(return_url, :layout => false)}, :callback => params[:callback]
      }
      format.html { return render return_url, :layout => false }
      format.js {
        return render :json => {:success => true, :html => render_to_string(return_url, :layout => false)}, :callback => params[:callback]
      }
    end
  end

  def vendor_widget
    render :layout => false
  end

  def prepare_response_json
    defatetime = Time.now.to_i
    html = html = render_to_string(:layout => false)
    json = {"html" => html}.to_json
    callback = params[:callback]
    jsonp = callback + "(" + json + ")"
  end

  def check_and_assigns_widget_default_values()
    params[:is_test] ||= 'false'
    @is_test = params[:is_test]
    @active_tabs_for_publisher = [5]
    @activate_tab = true
    @show_price = params[:show_price]
    @show_offer = params[:show_offer]
    item_ids = params[:item_ids] ? params[:item_ids].to_s.split(",") : []
    @path = params[:path]
    @moredetails = params[:price_full_details]

    url_params = set_cookie_for_temp_user_and_url_params_process(params)
    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    params[:ref_url] = url
    return url_params, url.to_s, itemsaccess, item_ids
  end

  def product_offers
    cookies[:plan_to_temp_user_id] = { value: SecureRandom.hex(20), expires: 1.year.from_now } if cookies[:plan_to_temp_user_id].blank?
    @moredetails = params[:price_full_details]
    item_ids = params[:item_ids] ? params[:item_ids].split(",") : [] 
    get_offers(item_ids)
    html = html = render_to_string(:layout => false)
    json = {"html" => html}.to_json
    callback = params[:callback]     
    jsonp = callback + "(" + json + ")"
    render :text => jsonp,  :content_type => "text/javascript" 
  end

  def get_offers(item_ids)
    params[:is_test] ||= 'false'
    url_params = "items:" + params[:item_ids]
    url = request.referer
    @item, @best_deals, @impression_id = ArticleContent.get_best_deals(item_ids, url, url_params, params[:is_test], current_user, request.remote_ip, cookies[:plan_to_temp_user_id])

    @vendors = VendorDetail.all unless @best_deals.blank?
  end

  def advertisement
    item_ids = params[:item_ids] ? params[:item_ids].split(",") : []
    content_id = ContentItemRelation.includes(:content).where('item_id=? and contents.type=?',item_ids[0],'AdvertisementContent').first.content_id
    @advertisement = Advertisement.find_by_content_id(content_id)
     html = html = render_to_string(:layout => false)
     json = {"html" => html}.to_json
     callback = params[:callback]     
     jsonp = calpublic/javascripts/search_planto.widget.jslback + "(" + json + ")"
     render :text => jsonp,  :content_type => "text/javascript"  
  end 
  
    def search_items
      # @types = params[:types].blank? ? ["Mobile", "Tablet", "Camera"] : params[:types].split(",")
      @page_type ||= "large_screen"
      @page_type = params[:page_type] unless params[:page_type].blank?

      @item_types =  params[:search_type].blank? ? "Mobile" : params[:search_type].split(",")

      if params[:term]
        @items = Sunspot.search(Product.search_type(@item_types)) do
          keywords params[:term].gsub("-",""), :fields => :name
          with :status,[1,2,3]
      #order_by :class, :desc
          paginate(:page => params[:page], :per_page => 10)
      #facet :types
          order_by :orderbyid , :asc
      #order_by :status, :asc      
          order_by :launch_date, :desc

        end
        @items = @items.results
      else
        @types = params[:types].blank? ? ["Mobile", "Tablet", "Camera"] : params[:types].split(",")
        @item_types =  params[:search_type].blank? ? "Mobile" : params[:search_type]
        unless $redis.get("#{@item_types}_top_item_ids_comparison").blank?
          @items = Item.includes([:attribute_values]).where("id in (?)", $redis.get("#{@item_types}_top_item_ids_comparison").split(","))
        else
          @items = Item.includes([:attribute_values]).find_by_sql("select items.* from items join (select item_id,impressions from item_ad_details order by impressions desc limit 1000) a on a.item_id = items.id and status = 1 and items.type in ('#{@item_types}')  limit 9")
          $redis.set("#{@item_types}_top_item_ids_comparison", @items.collect(&:id).join(","))
          $redis.expire "#{@item_types}_top_item_ids_comparison", 24.hours
        end  
        #{}@items = Item.joins(:itemtype, :add_impressions).select("items.*, count(add_impressions.item_id) as count").where("itemtypes.itemtype in(?) && date(impression_time) > date(?) and date(impression_time) < date(?)",item_types,(Date.today-30.days).strftime("%y-%m-%d"), Date.today.strftime("%y-%m-%d")).group("add_impressions.item_id").limit(10)
        
      end
      
        html = html = render_to_string(:layout => false)
        json = {"html" => html}.to_json
        callback = params[:callback]     
        jsonp = callback + "(" + json + ")"
        render :text => jsonp,  :content_type => "text/javascript"   
      
   end

   def product_autocomplete
    item_types =  params[:search_type].blank? ? params[:search_type].split(",") : ["Mobile", "Tablet", "Camera"]

     search_type = Product.search_type(item_types)
    search_type = Product.search_type(nil) if search_type.blank?
    @items = Sunspot.search(search_type) do
      keywords params[:term].gsub("-",""), :fields => :name
      with :status,[1,2,3]
      paginate(:page => 1, :per_page => 10) 
      order_by :orderbyid , :asc
      order_by :launch_date, :desc            
      #order_by :status,:asc
    end

   
    results = @items.results.collect{|item|
    # if item.type == "CarGroup"
     #   type = "Car"
     # else
     if(item.is_a? (Product))
        type = item.type.humanize
     elsif(item.is_a? (Content))
        type = item.sub_type   
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
     if  item.is_a?(Item)
      image_url = item.image_url(:small) rescue ""
      url = item.get_url() rescue ""
      # image_url = item.image_url
      {:id => item.id, :value => item.get_name, :imgsrc =>image_url, :type => type, :url => url }
       
    else
      image_url = item.content_photos.first.photo.url(:thumb) rescue "/images/prodcut_reivew.png"
      url = content_path(item)
      # image_url = item.image_url
      {:content_id => item.id, :value => Content.title_display(item.title)  , :imgsrc =>image_url, :type => type, :url => url } 
       end
    }
    
  # html = html = render_to_string(:layout => false)
        json = results

        callback = params[:callback]     
        jsonp = callback + "(" + json.to_json + ")"
    
        render :json => jsonp
  end

  
  def get_item_for_widget
    cookies[:plan_to_temp_user_id] = { value: SecureRandom.hex(20), expires: 1.year.from_now } if cookies[:plan_to_temp_user_id].blank?
    params[:is_test] ||= 'false'
    @is_test = params[:is_test]
    @test_condition = @is_test == "true" ? "&is_test=true" : ""

    @page_type ||= "large_screen"
    @page_type = params[:page_type] unless params[:page_type].blank?

    url = ""
    url_params = Advertisement.url_params_process(params)

    if(params[:ref_url] && params[:ref_url] != "" && params[:ref_url] != 'undefined' )
      url = params[:ref_url]
      itemsaccess = "ref_url"
    else
      itemsaccess = "referer"
      url = request.referer
    end

    @item = Item.find(params[:item_id].gsub("product_", ""))
 
    @where_to_buy_items = @item.itemdetails.includes(:vendor).where("status = 1 and isError = 0").order('sort_priority desc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
    # @impression_id = AddImpression.save_add_impression_data("pricecomparision",@item.id,request.referer,Time.zone.now,current_user,request.remote_ip,@impression_id)

    if @showspec == 1
      @item_specification_summary_lists = @item.attribute_values.includes(:attribute => :item_specification_summary_lists).where("attribute_values.item_id=? and item_specification_summary_lists.itemtype_id =?", @item.id, @item.itemtype_id).order("item_specification_summary_lists.sortorder ASC").group_by(&:proorcon)
      # @contents = Content.where(:sub_type => "Reviews")
      @item_specification_summary_lists.delete("nothing")
      @items_specification = {"Pro" => [], "Con" => []}
      @item_specification_summary_lists.each do |key, value|
      @items_specification[key[:key]] << {:values => value, description: key[:description],title: key[:title]} if key
      end
    end

    # @impression_id = SecureRandom.uuid
    # impression_params =  {:imp_id => @impression_id, :type => "pricecomparision", :itemid => @item.id, :request_referer => url, :time => Time.zone.now, :user => current_user.blank? ? nil : current_user.id, :remote_ip => request.remote_ip, :impression_id => nil, :itemaccess => itemsaccess,
    #                       :params => url_params, :temp_user_id => cookies[:plan_to_temp_user_id], :ad_id => nil}.to_json

    @impression_id = nil
    impression_params =  {:imp_id => @impression_id, :type => "pricecomparision", :itemid => @item.id, :request_referer => url, :time => Time.zone.now, :user => current_user.blank? ? nil : current_user, :remote_ip => request.remote_ip, :impression_id => nil, :itemaccess => itemsaccess,
                          :params => url_params, :temp_user_id => cookies[:plan_to_temp_user_id], :ad_id => nil}

    # Resque.enqueue(CreateImpressionAndClick, 'AddImpression', impression_params) if @is_test != "true"
    @impression_id = AddImpression.add_impression_to_resque(impression_params[:type], impression_params[:item_id], impression_params[:request_referer], impression_params[:user], impression_params[:remote_ip], impression_params[:impression_id], impression_params[:itemaccess], impression_params[:params], impression_params[:temp_user_id], impression_params[:ad_id], nil) if @is_test != "true"

        html = html = render_to_string(:layout => false)
        json = {"html" => html}.to_json
        callback = params[:callback]     
        jsonp = callback + "(" + json + ")"
        render :text => jsonp,  :content_type => "text/javascript" 
  end

  def show_search_widget
     render tmpllate: 'show_search_widget', :layout => false
  end

  def get_item_item_advertisment
    @height = params[:height] ? params[:height] : 250
    @width = params[:width] ? params[:width] : 250
    # item_ids = ContentItemRelation.includes(:content).where('contents.url=? and contents.type=?',request.referer,'ArticleContent')
    # content_id = ContentItemRelation.includes(:content).where('item_id=? and contents.type=?',item_ids[0],'AdvertisementContent').first.content_id
    unless params[:dynamic]
      @advertisement = Advertisement.joins(:content => [:items => :contents]).where("view_article_contents.url=?", request.referer)
      render :template => "products/get_static_item_advertisment",:layout => false
    else
      @ac = ArticleContent.includes(:items).where("view_article_contents.url=?", request.referer)
      unless @ac.blank?
        @item = @ac.first.item
        @where_to_buy = @item.itemdetails.includes(:vendor).where('itemdetails.isError =?',0).order('itemdetails.status asc, sort_priority desc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
      else
        @where_to_buy = []
      end
      html = html = render_to_string(:layout => false)
        json = {"html" => html}.to_json
        callback = params[:callback]     
        jsonp = callback + "(" + json + ")"
        render :text => jsonp,  :content_type => "text/javascript" 

      # render :template => "products/get_dynamic_item_advertisment",:layout => false
    end
  end

  def create_impression_before_widgets
    params[:price_full_details] ||= "true"
    host_name = configatron.hostname.gsub(/(http|https):\/\//, '')
    params[:request_referer] ||= request.referer
    params[:request_referer] ||= ""
    params[:ref_url] ||= ""
    params[:path] ||= ""
    params[:sort_disable] ||= "false"

    @publisher = Publisher.where(:id => params[:publisher_id]).last if !params[:publisher_id].blank?

    if (params[:item_ids].blank? && params[:ref_url].blank?)
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("price_full_details", "path", "sort_disable", "request_referer"))
    elsif params[:item_ids].blank?
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("price_full_details", "path", "sort_disable", "ref_url"))
    else
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("price_full_details", "path", "sort_disable", "item_ids"))
    end
    cache_params = CGI::unescape(cache_params)

    cache_key = "views/#{host_name}/where_to_buy_items.js?#{cache_params}.js"

    if params[:is_test] != "true"
      cache = Rails.cache.read(cache_key)
      unless cache.blank?
        valid_html = cache.match(/_blank/).blank? ? false : true
        cache = reset_json_callback(cache, params[:callback])
        if valid_html
          url_params = set_cookie_for_temp_user_and_url_params_process(params)
          item_id = params[:item_ids]
          matched_val = cache.match(/present_item_id=.*#/)
          unless matched_val.blank?
            val = matched_val[0]
            item_id = val.split("=")[1].gsub("#", "")
          end
          @impression_id = Advertisement.create_impression_before_cache(params, request.referer, url_params, cookies[:plan_to_temp_user_id], nil, request.remote_ip, "pricecomparision", item_id, nil)

          cache = cache.gsub(/iid=\S+\\/, "iid=#{@impression_id}\\")
        end
        return render :text => cache.html_safe, :content_type => "text/javascript"
        ## Rails.cache.write(cache_key, cache)
      end
    end
  end


  def create_impression_before_widgets_vendor
    params[:price_full_details] ||= "true"
    host_name = configatron.hostname.gsub(/(http|https):\/\//, '')
    params[:request_referer] ||= request.referer
    params[:request_referer] ||= ""
    params[:ref_url] ||= ""
    params[:item_ids] ||= ""
    params[:path] ||= ""
    params[:page_type] ||= "type_1"
    params[:sort_disable] ||= "false"
    params[:geo] ||= "in"

    if (params[:item_ids].blank? && !params[:ref_url].blank?)
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("page_type", "path", "price_full_details", "sort_disable", "ref_url", "geo"))
    elsif (params[:item_ids].blank? && params[:ref_url].blank?)
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("page_type", "path", "price_full_details", "sort_disable", "request_referer", "geo"))
    elsif !params[:item_ids].blank?
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("item_ids", "page_type", "path", "price_full_details", "sort_disable", "geo"))
    end
    cache_params = CGI::unescape(cache_params)

    cache_key = "views/#{host_name}/where_to_buy_items_vendor.js?#{cache_params}.js"

    if params[:is_test] != "true"
      cache = Rails.cache.read(cache_key)
      unless cache.blank?
        valid_html = cache.match(/_blank/).blank? ? false : true
        cache = reset_json_callback(cache, params[:callback])
        if valid_html
          url_params = set_cookie_for_temp_user_and_url_params_process(params)
          item_id = params[:item_ids]
          matched_val = cache.match(/present_item_id=.*#/)
          unless matched_val.blank?
            val = matched_val[0]
            item_id = val.split("=")[1].gsub("#", "")
          end
          @impression_id = Advertisement.create_impression_before_cache(params, request.referer, url_params, cookies[:plan_to_temp_user_id], nil, request.remote_ip, "fashion", item_id, nil)

          cache = cache.gsub(/iid=\S+\\/, "iid=#{@impression_id}\\")
        end
        return render :text => cache.html_safe, :content_type => "text/javascript"
        ## Rails.cache.write(cache_key, cache)
      end
    end
  end

  def create_impression_before_sports_widget
    params[:price_full_details] ||= "true"
    host_name = configatron.hostname.gsub(/(http|https):\/\//, '')
    params[:request_referer] ||= request.referer
    params[:ref_url] ||= ""
    params[:item_ids] ||= ""
    params[:page_type] ||= "type_1"
    params[:category_item_detail_id] ||= ""
    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    params[:ref_url] = url
    params[:ref_url] ||= ""
    params[:random_id] ||= ""

    #Get dynamic id from url

    if (params[:page_type] == "type_4")
      random_id = rand(20)
      params[:random_id] = random_id
    elsif (params[:page_type] == "type_6")
      random_id = rand(100)
      params[:random_id] = random_id
    end

    sub_category, sub_category_condition = Item.get_sub_category_and_condition_from_url(url)

    params[:category_type] = sub_category

    records_count = $redis.get("sports_widget1:#{sub_category}:#{params[:page_type]}")
    if(records_count != nil)
      p "printing  - " + "sports_widget1:#{sub_category}:#{params[:page_type]}" + " - " + records_count
    end
  
    if (!records_count.blank?)
      records_count = records_count.to_i
      offset = rand(records_count)
      if offset == 0
        offset = rand(records_count)
      end
      params[:category_item_detail_id] = offset
    end

    cache_params = ""
    if !params[:item_ids].blank?
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("item_ids", "category_item_detail_id", "page_type", "random_id"))
    else
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("category_item_detail_id", "category_type", "page_type", "random_id"))
    end
    cache_params = CGI::unescape(cache_params)

    cache_key = "views/#{host_name}/sports_widget.js?#{cache_params}.js"

    if params[:is_test] != "true"
      cache = Rails.cache.read(cache_key)
      unless cache.blank?
        valid_html = cache.match(/_blank/).blank? ? false : true
        cache = reset_json_callback(cache, params[:callback])
        if valid_html
          url_params = set_cookie_for_temp_user_and_url_params_process(params)
          item_id = params[:item_ids]
          ## have to implement to store the category_item_details
          category_item_detail_id = FeedUrl.get_value_from_pattern(cache, "item_id=<item_id>&amp;", "<item_id>")
          @impression_id = Advertisement.create_impression_before_cache(params, request.referer, url_params, cookies[:plan_to_temp_user_id], nil, request.remote_ip, "amazon_sports_widget", category_item_detail_id, nil)

          old_iid = FeedUrl.get_value_from_pattern(cache, "iid=<iid>&amp;", "<iid>")
          cache = cache.gsub(old_iid, @impression_id)
        end
        return render :text => cache.html_safe, :content_type => "text/javascript"
        ## Rails.cache.write(cache_key, cache)
      end
    end
  end

  def create_impression_before_elec_widget
    params[:price_full_details] ||= "true"
    host_name = configatron.hostname.gsub(/(http|https):\/\//, '')
    params[:request_referer] ||= request.referer
    params[:item_ids] ||= "" if params[:item_ids].blank?
    params[:page_type] ||= "type_1"
    params[:page_type] = "type_1" if params[:page_type].blank?
    params[:category_item_detail_id] ||= ""
    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    params[:ref_url] = url
    params[:ref_url] = "" if params[:ref_url].blank?
    @ref_url = params[:ref_url]
    params[:vendor_ids] ||= ""
    params[:ret_format] ||= ""
    params[:is_test] ||= "false"

    if params[:ret_format] == "html"
      params[:format] = "html"
      extname = "html"
    elsif params[:ret_format] == "xml"
      params[:format] = "xml"
      extname = "xml"
    else
      extname = "js"
    end

    params[:is_test] = "false" if params[:ref_url].to_s.include?("gizbot.com")

    cache_params = ""
    if !params[:item_ids].blank?
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("item_ids", "page_type", "vendor_ids", "ret_format"))
    else
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("ref_url", "page_type", "vendor_ids", "ret_format"))
    end
    cache_params = CGI::unescape(cache_params)

    cache_key = "views/#{host_name}/elec_widget_1.#{extname}?#{cache_params}.#{extname}"

    if params[:is_test] != "true"
      cache = Rails.cache.read(cache_key)
      unless cache.blank?
        valid_html = cache.match(/_blank/).blank? ? false : true
        cache = reset_json_callback(cache, params[:callback]) if extname == "js"
        if valid_html
          url_params = set_cookie_for_temp_user_and_url_params_process(params)
          @impression_id = Advertisement.create_impression_before_cache(params, request.referer, url_params, cookies[:plan_to_temp_user_id], nil, request.remote_ip, "elec_widget_1", params[:item_ids], nil)

          old_iid = FeedUrl.get_value_from_pattern(cache, "iid=<iid>&", "<iid>")
          cache = cache.gsub(old_iid, @impression_id)
        end

        if extname == "js"
          return render :text => cache.html_safe, :content_type => "text/javascript"
        else
          return render :text => cache.html_safe
        end
        ## Rails.cache.write(cache_key, cache)
      end
    end
  end

  def create_impression_before_price_text_vendor_details
    params[:price_full_details] ||= "true"
    host_name = configatron.hostname.gsub(/(http|https):\/\//, '')
    params[:request_referer] ||= request.referer
    params[:ref_url] ||= ""
    params[:item_ids] ||= ""
    params[:page_type] ||= "type_1"
    params[:category_item_detail_id] ||= ""
    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    params[:ref_url] = url
    params[:ref_url] ||= ""
    params[:ascsubtag] ||= ""

    cache_params = ""
    if !params[:item_ids].blank?
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("item_ids", "page_type"))
    else
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("ref_url", "page_type"))
      cache_params = CGI::unescape(cache_params)
    end
    cache_key = "views/#{host_name}/price_text_vendor_details.js?#{cache_params}.js"

    if params[:is_test] != "true"
      cache = Rails.cache.read(cache_key)
      unless cache.blank?
        valid_html = cache.match(/_blank/).blank? ? false : true
        cache = reset_json_callback(cache, params[:callback])
        if valid_html
          url_params = set_cookie_for_temp_user_and_url_params_process(params)
          @impression_id = Advertisement.create_impression_before_cache(params, request.referer, url_params, cookies[:plan_to_temp_user_id], nil, request.remote_ip, "elec_widget_1", params[:item_ids], nil)

          old_iid = FeedUrl.get_value_from_pattern(cache, "iid=<iid>&", "<iid>")
          cache = cache.gsub(old_iid, @impression_id)

          if !params[:ascsubtag].blank?
            old_sub_tag = FeedUrl.get_value_from_pattern(cache, "ascsubtag%3D<subtag>>", "<subtag>")
            old_sub_tag = "ascsubtag%3D" + old_sub_tag.to_s
            cache = cache.gsub(old_sub_tag, "ascsubtag%3D#{params[:ascsubtag]}")
          end
        end
        return render :text => cache.html_safe, :content_type => "text/javascript"
        ## Rails.cache.write(cache_key, cache)
      end
    end
  end

  def check_and_assigns_ad_default_values()
    params[:is_test] ||= 'false'
    @is_test = params[:is_test]
    @moredetails = params[:price_full_details]
    @activate_tab = true
    @ad_template_type ||= "type_1"
    impression_type = params[:ad_as_widget] == "true" ? "advertisement_widget" : "advertisement"
    #TODO: temp commentted no one is using now
    # @vendor_ids = params[:more_vendors] == "true" ? [9861, 9882, 9874, 9880, 9856, 72329] : []
    @vendor_ids = params[:vendor_ids].to_s.split(",")
    @ref_url = params[:ref_url] ||= ""
    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    @ref_url = url

    vendor_ids = [9882]
    url_params = set_cookie_for_temp_user_and_url_params_process(params)
    winning_price_enc = params[:wp]
    return impression_type, url, url_params, itemsaccess, vendor_ids, nil, winning_price_enc
  end

  def create_impression_before_widget_for_women
    params[:item_ids] ||= ""
    params[:page_type] ||= ""
    params[:fashion_id] ||= ""
    params[:beauty] ||= "false"

    @publisher = Publisher.where(:id => params[:publisher_id]).last if !params[:publisher_id].blank?

    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    params[:ref_url] = url

    @items, @url, from_article_field = Item.get_items_from_url(url, params[:item_ids])

    if @url.to_s.include?("bebeautiful.in")
      params[:beauty] = "true"
    end

    if !@items.flatten.blank?
      params[:item_ids] = @items.flatten.map(&:id).compact.join(",")
      included_beauty = @items.flatten.map {|d| d.is_a?(Beauty)}.include?(true) rescue false
      if included_beauty || from_article_field
        params[:beauty] = "true"
      end
    end

    if params[:beauty] != "true" && (params[:item_ids].blank? && params[:fashion_id].blank?)
      # item_id, random_id = Item.get_item_id_and_random_id(nil, params[:item_ids], 9882)
      #
      # if random_id.blank?
      #   item_id, random_id = Item.get_item_id_and_random_id(nil, params[:item_ids], 9882)
      # end

      random_id = rand(20)

      # params[:item_ids] = item_id
      params[:fashion_id] = random_id
    end

    host_name = configatron.hostname.gsub(/(http|https):\/\//, '')

    if params[:beauty] == "true"
      if params[:item_ids].blank?
        cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("ref_url", "page_type", "geo", "beauty"))
      else
        cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("item_ids", "page_type", "geo", "beauty"))
      end
    else
      if params[:item_ids].blank?
        cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("ref_url", "page_type", "fashion_id", "geo", "beauty"))
      else
        cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("item_ids", "page_type", "fashion_id", "geo", "beauty"))
      end
    end

    cache_params = CGI::unescape(cache_params)
    cache_key = "views/#{host_name}/widget_for_women.js?#{cache_params}.js"

    if params[:is_test] != "true"
      cache = Rails.cache.read(cache_key)
      unless cache.blank?
        valid_html = cache.match(/_blank/).blank? ? false : true
        cache = reset_json_callback(cache, params[:callback])
        if valid_html
          url_params = set_cookie_for_temp_user_and_url_params_process(params)
          item_id = params[:item_ids]
          matched_val = cache.match(/present_item_id=.*#/)
          unless matched_val.blank?
            val = matched_val[0]
            item_id = val.split("=")[1].gsub("#", "")
          end
          @impression_id = Advertisement.create_impression_before_cache(params, request.referer, url_params, cookies[:plan_to_temp_user_id], nil, request.remote_ip, "fashion", item_id, nil)

          cache = cache.gsub(/iid=\S+\\/, "iid=#{@impression_id}\\")
        end
        return render :text => cache.html_safe, :content_type => "text/javascript"
        ## Rails.cache.write(cache_key, cache)
      end
    end
  end

  private

  def get_item_object
    @item = Item.find(params[:id])
  end

  def reset_json_callback(cache, callback)
    cache = cache.sub(/^\w+\((.*)\)$/, '\1')
    cache = callback.present? ? "#{callback}(#{cache})" : cache
    return cache
  end
end
