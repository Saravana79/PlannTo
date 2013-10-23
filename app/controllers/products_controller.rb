class ProductsController < ApplicationController
  caches_action :show,  :cache_path => Proc.new { |c| 
    if(current_user)
      c.params.merge(user: 1) 
    else
      c.params.merge(user: 0) 
    end
     }
  before_filter :authenticate_user!, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
  before_filter :get_item_object, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type, :review_it, :add_item_info]
  before_filter :all_user_follow_item, :if => Proc.new { |c| !current_user.blank? }
  before_filter :store_location, :only => [:show]
  before_filter :set_referer,:only => [:show]
  before_filter :log_impression, :only=> [:show]
  layout 'product'
  include FollowMethods
  include ItemsHelper
#  layout false, only: [:where_to_buy_items]

 def log_impression
   @item = Item.find(params[:id])
   @item.impressions.create(ip_address: request.remote_ip,user_id:(current_user.id rescue ''))
 end
  def set_referer
    @item = Item.find(params[:id])
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
    @item = Item.includes([:itemdetails => :vendor],[:attribute_values], :itemrelationships, :item_rating).find(params[:id])#where(:id => params[:id]).includes(:item_attributes).last
    @pro_cons = ItemProCon.find_by_sql("select *, count(*) as count from item_pro_cons 
        where item_id = #{@item.id} and pro_con_category_id is not null group by pro_con_category_id, proorcon
        union 
        select *, 1 as count from item_pro_cons 
        where item_id = #{@item.id} and pro_con_category_id is null 
        order by count desc, (case when pro_con_category_id is null then 99999 else pro_con_category_id end) asc, letters_count desc, `index` 
        ")
    @pro_cons = @pro_cons.group_by(&:proorcon)
    @verdicts = ArticleContent.find_by_sql("select ac.* from article_contents ac inner join contents c on c.id = ac.id inner join item_contents_relations_cache icc on icc.content_id = ac.id left outer join facebook_counts fc on fc.content_id = ac.id where icc.item_id = #{@item.id} and c.sub_type = 'Reviews' and ac.field4 is not null and trim(ac.field4) != '' and ac.video is null and c.status = 1  order by (if(total_votes is null,0,total_votes) + like_count + share_count) desc limit 6" )
    @new_version_item = Item.find(@item.new_version_item_id) if (@item.new_version_item_id && @item.new_version_item_id != 0)
    if !current_user
      @custom = "true"
    end 
    @no_custom = "true" if @item.type == "Topic" 
    session[:itemtype] = @item.get_base_itemtype
    @where_to_buy_items = @item.itemdetails.where("status = 1 and isError = 0").order('(itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
    @attribute_degree_view = @attribute_degree_view = @item.attribute_values.collect{|ia| ia if ia.attribute_id == 294}.compact.first.value rescue ""
    
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
    if (@item.is_a? Product)
      @article_categories = ArticleCategory.get_by_itemtype(@item.itemtype_id)
     # @article_categories = ArticleCategory.by_itemtype_id(@item.itemtype_id).map { |e|[e.name, e.id]  }
    else
      @article_categories = ArticleCategory.get_by_itemtype(0)
     # @article_categories = ArticleCategory.by_itemtype_id(0).map { |e|[e.name, e.id]  }
    end    
    if((@item.is_a? Product) &&  (!@item.manu.nil?))
      @dealer_locators =  DealerLocator.find_by_item_id(@item.manu.id)
    end 

    @top_contributors = @item.get_top_contributors
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
    @item = Item.where(:id => params[:id]).last    
    @follow_type = params[:follow_type]
    respond_to do |format|
      format.js { render :partial=> 'itemrelationships/relateditem', :collection => @item.unfollowing_related_items(current_user, 2) }
    end

  end
  
  
  def external_page
    @item = Item.find(params[:item_id])
    @showspec = params[:show_spec].blank? ? 0 : params[:show_spec] 
    @showcompare = params[:show_compare].blank? ? 0 : params[:show_compare]
    @showreviews = params[:show_reviews].blank? ? 0 : params[:show_reviews]
    @impression_id = params[:iid]
    unless request.referer
      @req = request.referer  
    end
     
    @where_to_buy_items = @item.itemdetails.where("status = 1 and isError = 0").order('(itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
    @impression_id = AddImpression.save_add_impression_data("pricecomparision",@item.id,request.referer,Time.now,current_user,request.remote_ip,@impression_id)
    @item_specification_summary_lists = @item.attribute_values.includes(:attribute => :item_specification_summary_lists).where("attribute_values.item_id=? and item_specification_summary_lists.itemtype_id =?", @item.id, @item.itemtype_id).order("item_specification_summary_lists.sortorder ASC").group_by(&:proorcon)
   # @contents = Content.where(:sub_type => "Reviews")
    @item_specification_summary_lists.delete("nothing")
    @items_specification = {"Pro" => [], "Con" => []}
    @item_specification_summary_lists.each do |key, value|
    @items_specification[key[:key]] << {:values => value, description: key[:description],title: key[:title]} if key
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
    item_ids = params[:item_ids] ? params[:item_ids].split(",") : [] 
    unless (item_ids.blank?)
      if (true if Float(item_ids[0]) rescue false)
        @items = Item.where(id: item_ids) 
      else
        @items = Item.where(slug: item_ids)
      end
    else
        #url = request.referer
        url = params[:ref_url]
        @articles = ArticleContent.where(url: url)
        unless @articles.empty?
          @items = @articles[0].items;      
        end
    end 

    unless @items.nil? || @items.empty?
      @item = @items[0] 
      @moredetails = params[:price_full_details]
      @where_to_buy_items = @item.itemdetails.where("status = 1 and isError = 0").order('(itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
      @impression_id = AddImpression.save_add_impression_data("pricecomparision",@item.id,request.referer,Time.now,current_user,request.remote_ip,nil)
      responses = []
        @where_to_buy_items.group_by(&:site).each do |site, items|  
          items.each_with_index do |item, index|     
            display_item_details(item)
            if index == 0
              responses << {image_url: item.image_url, display_price: display_price_detail(item), history_detail: "/history_details?detail_id=#{item.item_details_id}"}
            end
          end
        end
      address = Geocoder.search(request.ip)
      defatetime = Time.now.to_i
      html = html = render_to_string(:layout => false)
      json = {"html" => html}.to_json
      callback = params[:callback]     
      jsonp = callback + "(" + json + ")"
      render :text => jsonp,  :content_type => "text/javascript"  
    else
      @where_to_buy_items =[]
      render :text => "",  :content_type => "text/javascript"
    end
  end
  
  def advertisement
    item_ids = params[:item_ids] ? params[:item_ids].split(",") : []
    content_id = ContentItemRelation.includes(:content).where('item_id=? and contents.type=?',item_ids[0],'AdvertisementContent').first.content_id
    @advertisement = Advertisement.find_by_content_id(content_id)
     html = html = render_to_string(:layout => false)
     json = {"html" => html}.to_json
     callback = params[:callback]     
     jsonp = callback + "(" + json + ")"
     render :text => jsonp,  :content_type => "text/javascript"  
  end 
  
  private

  def get_item_object
    @item = Item.find(params[:id])
  end
end
