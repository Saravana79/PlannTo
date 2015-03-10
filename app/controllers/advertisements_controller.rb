class AdvertisementsController < ApplicationController
  include Admin::AdvertisementsHelper
  layout "product"

  before_filter :create_impression_before_show_ads, :only => [:show_ads], :if => lambda { request.format.html? }
  caches_action :show_ads, :cache_path => proc {|c|  params[:item_id].blank? ? params.slice("ads_id", "size", "more_vendors", "ref_url", "page_type", "click_url", "protocol_type", "r") : params.slice("item_id", "ads_id", "size", "more_vendors", "page_type", "click_url", "protocol_type", "r") }, :expires_in => 2.hours, :if => lambda { request.format.html? && params[:is_test] != "true" }

  before_filter :create_impression_before_show_video_ads, :only => [:video_ads]
  before_filter :set_access_control_headers, :only => [:video_ads, :video_ad_tracking]
  caches_action :video_ads, :cache_path => proc {|c| params.slice("item_id", "ads_id", "size", "format") }, :expires_in => 2.hours, :if => lambda { params[:is_test] != "true" }

  skip_before_filter :cache_follow_items, :store_session_url, :only => [:show_ads, :video_ads]
  #after_filter :set_access_control_headers, :only => [:video_ads, :video_ad_tracking]
  def show_ads
    #TODO: everything is clickable is only updated for type1 have to update for type2
    impression_type, url, url_params, itemsaccess, vendor_ids, ad_id, winning_price_enc = check_and_assigns_ad_default_values()
    @sid = sid = params[:sid] ||= ""

    # TODO: hot coded values, have to change in feature
    if @suitable_ui_size == "120" && params[:page_type] != "type_4"
      @ad_template_type = ad_id == 21 ? "type_3" : "type_2"
    end

    @ad_template_type = params[:page_type] unless params[:page_type].blank?

    # params[:page_type] = @ad_template_type
    #
    # url_params = Advertisement.make_url_params(params)

    if !@ad.blank? && @ad.advertisement_type == "fashion"
      return fashion_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, params[:item_id], vendor_ids)
    elsif !@ad.blank? && (@ad.advertisement_type == "static" || @ad.advertisement_type == "flash")
      return static_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid)
    elsif !@ad.blank? && @ad.id == 24
      return show_ad_layout(impression_type, url, itemsaccess, url_params, winning_price_enc, sid)
    end

    p_item_ids = item_ids = []
    p_item_ids = item_ids = params[:item_id].split(",") unless params[:item_id].blank?
    sort_disable = params[:r].to_i == 1 ? "true" : "false"
    @items, itemsaccess, url = Item.get_items_by_item_ids(item_ids, url, itemsaccess, request, false, sort_disable)

    return show_plannto_ads() if !@ad.blank? && @ad.advertisement_type == "plannto"

    status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
    publisher = Publisher.getpublisherfromdomain(url)

    #TODO: temp commented no one is using now
    # vendor_ids = Vendor.get_vendor_ids_by_publisher(publisher, vendor_ids) if params[:more_vendors] == "true"

    item_ids = @items.blank? ? [] : @items.map(&:id)
    @item = @items.first

    @item_details = Itemdetail.get_item_details_by_item_ids_count(item_ids, vendor_ids, @items, @publisher, status, params[:more_vendors], p_item_ids)

    # Default item_details based on vendor if item_details empty
    #TODO: temporary solution, have to change based on ecpm
    if @item_details.blank? && ad_id == 2 && impression_type != "advertisement_widget"
      #TODO: - Saravana - temporarily redirecting to static image ad. we need to implement this.
      @ad = Advertisement.get_ad_by_id(4).first
      return static_ad_process(impression_type, url, itemsaccess="MissingURL", url_params, winning_price_enc, sid)
    else
      @item_details = Click.get_item_details_when_ad_not_as_widget(impression_type, @item_details, vendor_ids)
      @vendor_image_url = configatron.root_image_url + "vendor/medium/default_vendor.jpeg"
      @vendor_ad_details = vendor_ids.blank? ? {} : VendorDetail.get_vendor_ad_details(vendor_ids)
      if @is_test != "true"
        @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids.first, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], ad_id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
        Advertisement.check_and_update_act_spent_budget_in_redis(ad_id, winning_price_enc)
      end

      @item_details = @item_details.uniq(&:url)
      @item_details, @sliced_item_details, @item, @items = Item.assign_template_and_item(@ad_template_type, @item_details, @items, @suitable_ui_size)
      if (@suitable_ui_size == "300_600" && @item_details.count < 3)
        old_item_details = @item_details
        new_item_ids = Item.get_item_ids_for_300_600()
        @item_details = Itemdetail.get_item_details_by_item_ids_count(new_item_ids, vendor_ids, @items=[], @publisher, status, params[:more_vendors], p_item_ids)
        @item_details = old_item_details + @item_details
        @item_details, @sliced_item_details, @item, @items = Item.assign_template_and_item(@ad_template_type, @item_details, @items=[], @suitable_ui_size)
      end
      if @suitable_ui_size == "300_600" && params[:page_type] != "type_4"
        @ad_template_type = ad_id == 21 ? "type_3" : "type_1"
      end
      @click_url = params[:click_url] =~ URI::regexp ? params[:click_url] : ""
      @click_url = @click_url.gsub("&amp;", "&")
    end

    respond_to do |format|
      format.json {
        if @item_details.blank?
          render :json => {:success => false, :html => ""}, :callback => params[:callback]
        else
          render :json => {:success => @item_details.blank? ? false : true, :html => render_to_string("advertisements/show_ads.html.erb", :layout => false)}, :callback => params[:callback]
        end
      }
      format.html {
        if @item_details.blank?
          render :nothing => true
        else
          render :layout => false
        end
      }
    end
  end

  def video_ads
    #params[:ref_url] ||= "http://gadgetstouse.com/full-reviews/gionee-elife-e6-review/11205"

    @show_companion = params[:size] == "0x0" ? "false" : "true"

    @width, @height = params[:size].to_s.split("x")

    @advertisement = Advertisement.where(:id => params[:ads_id]).first
    @ad_video_detail = @advertisement.ad_video_detail

    if !@ad_video_detail.blank?
      @skippable = @ad_video_detail.skip
      @skippable_time = @ad_video_detail.skip_time
      @total_video_time = @ad_video_detail.total_time.to_s

      @flv_details, @wmv_details, @webm_details, @mp4_details = @ad_video_detail.video_details.to_s.split(">>").map {|x| x.split(",")}
    end

    if !params[:vskip].blank?
      @skippable = params[:vskip] == "BLOCK_SKIPPABLE" ? false : true
    end

    if !params[:vdur].blank?
      @total_video_time = params[:vdur] if params[:vdur] < @total_video_time
    end

    @impression_id = VideoImpression.add_video_impression_to_resque(params, request.remote_ip) if params[:is_test] != "true"
    item_detail_id = Advertisement.get_video_click_url(params[:item_id])
    if item_detail_id.blank?
      @video_click_url = configatron.hostname + history_details_path(:ads_id => @advertisement.id, :iid => @impression_id, :red_url => @ad_video_detail.linear_click_url, :video_impression_id => @impression_id)
    else
      params[:video_impression_id] = @impression_id
      # @video_click_url = get_ad_url(item_detail_id, @impression_id, params[:ref_url], params[:sid], params[:ads_id], params)
      @video_click_url = configatron.hostname + history_details_path(:detail_id => item_detail_id, :ads_id => @advertisement.id, :iid => @impression_id, :ref_url => params[:ref_url], :video_impression_id => @impression_id)
    end
    @companion_dynamic_url = "#{configatron.hostname}/advertisments/show_ads?item_id=#{params[:item_id]}&ads_id=#{params[:ads_id]}&size=#{params[:size]}&ref_url=#{params[:ref_url]}&device=#{params[:device]}&sid=#{params[:sid]}&t=#{params[:t]}&r=#{params[:r]}&a=#{params[:a]}&video=true&video_impression_id=#{@impression_id}"
  end

  def video_ad_tracking
    VideoAdEvent.create(:video_impression_id => params[:impression_id], :event_name => params[:metric])
    render :nothing => true
  end

  def show_plannto_ads
    @item = @items.first
    item_details = @item.blank? ? [] : Itemdetail.get_item_detail_with_lowest_price(@item.id)
    item_details.delete_if {|a| a.price == 0.0}
    @item_detail = item_details.first

    respond_to do |format|
      format.json {
        if @item_detail.blank?
          render :json => {:success => false, :html => ""}, :callback => params[:callback]
        else
          render :json => {:success => @item_detail.blank? ? false : true, :html => render_to_string("advertisements/show_plannto_ads.html.erb", :layout => false)}, :callback => params[:callback]
        end
      }
      format.html { render :layout => false }
    end
  end

  def check_and_assigns_ad_default_values()
    params[:is_test] ||= 'false'
    @is_test = params[:is_test]
    @moredetails = params[:price_full_details]
    @activate_tab = true
    params[:more_vendors] ||= "false"
    @ad_template_type ||= "type_1"
    impression_type = params[:ad_as_widget] == "true" ? "advertisement_widget" : "advertisement"
    #TODO: temp commentted no one is using now
    # @vendor_ids = params[:more_vendors] == "true" ? [9861, 9882, 9874, 9880, 9856, 72329] : []
    @vendor_ids = []
    @ref_url = params[:ref_url] ||= ""
    @iframe_width, @iframe_height = params[:size].split("x")
    @suitable_ui_size = Advertisement.process_size(@iframe_width, @iframe_height)
    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    @ref_url = url
    @ad = Advertisement.get_ad_by_id(params[:ads_id]).first

    @cookie_match = CookieMatch.find_user(cookies[:plan_to_temp_user_id]).first
    vendor_ids, ad_id, @ad_template_type = assign_ad_and_vendor_id(@ad, @vendor_ids)
    url_params = set_cookie_for_temp_user_and_url_params_process(params)
    winning_price_enc = params[:wp]
    return impression_type, url, url_params, itemsaccess, vendor_ids, ad_id, winning_price_enc
  end

  def static_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid)
    # static ad process
    @publisher = Publisher.getpublisherfromdomain(@ad.click_url)

    @image = @ad.images.where(:ad_size => params[:size]).first

    @image = @ad.images.first if @image.blank?

    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, nil, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
      Advertisement.check_and_update_act_spent_budget_in_redis(@ad.id, winning_price_enc)
    end
    @click_url = params[:click_url] =~ URI::regexp ? params[:click_url] : ""
    @click_url = @click_url.gsub("&amp;", "&")

    respond_to do |format|
      format.json {
        return render :json => {:success => true, :html => render_to_string("advertisements/show_static_ads.html.erb", :layout => false)}, :callback => params[:callback]
      }
      format.html { return render "show_static_ads.html.erb", :layout => false }
    end
  end

  def fashion_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, item_id, vendor_ids)
    # static ad process
    @publisher = Publisher.getpublisherfromdomain(@ad.click_url)

    @ad_template_type = "type_1" #TODO: only accept type 1

    @vendor = Vendor.where(:name => "Amazon").first
    vendor_ids = [@vendor.id]
    @vendor_image_url = configatron.root_image_url + "vendor/medium/default_vendor.jpeg"
    @vendor_ad_details = vendor_ids.blank? ? {} : VendorDetail.get_vendor_ad_details(vendor_ids)

    @current_vendor = @vendor_ad_details[@vendor.id]
    @current_vendor = {} if @current_vendor.blank?
    item_ids = item_id.to_s.split(",")

    @item, @item_details = Item.get_item_and_item_details_from_fashion_url(url, item_ids, vendor_ids)
    @sliced_item_details = @item_details.each_slice(2)

    p @item
    p @item_details
    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, nil, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
      Advertisement.check_and_update_act_spent_budget_in_redis(@ad.id, winning_price_enc)
    end

    @click_url = params[:click_url] =~ URI::regexp ? params[:click_url] : ""
    @click_url = @click_url.gsub("&amp;", "&")

    respond_to do |format|
      format.json {
        return render :json => {:success => true, :html => render_to_string("advertisements/show_fashion_ads.html.erb", :layout => false)}, :callback => params[:callback]
      }
      format.html { return render "show_fashion_ads.html.erb", :layout => false }
    end
  end

  def show_ad_layout(impression_type, url, itemsaccess, url_params, winning_price_enc, sid)
    # static ad process
    params[:only_layout] = "true"
    @publisher = Publisher.getpublisherfromdomain(@ad.click_url)

    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, nil, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
      Advertisement.check_and_update_act_spent_budget_in_redis(@ad.id, winning_price_enc)
    end
    @click_url = params[:click_url] =~ URI::regexp ? params[:click_url] : ""
    @click_url = @click_url.gsub("&amp;", "&")
    @size = params[:size].to_s
    @random = Random.rand(10 ** 10).to_s.rjust(10,'0')

    respond_to do |format|
      format.json {
        return render :json => {:success => true, :html => render_to_string("advertisements/show_ad_layout.html.erb", :layout => false)}, :callback => params[:callback]
      }
      format.html { return render "show_ad_layout.html.erb", :layout => false }
    end
  end

  def delete_ad_image
    image = Image.find_by_id(params[:id])
    image_id = image.id
    image.destroy
    render :js => "$('##{image_id}').remove(); alert('Image deleted successfully');"
  end

  def test_ads
    if params[:commit] == "Clear"
      params[:item_id] = ""
      params[:ref_url] = "http://gadgetstouse.com/full-reviews/gionee-elife-e6-review/11205"
      params[:ads_id] = 1
      params[:more_vendors] = false
      params[:page_type] ||= "small_screen"
      params[:is_test] = "true"
      params[:show_list] = ["All","widget-1",  "ad-300", "ad-120", "ad-728"]
    else
      params[:item_id] ||= "" #5414,1469
      params[:ref_url] ||= "http://gadgetstouse.com/full-reviews/gionee-elife-e6-review/11205"
      params[:ads_id] ||= 1
      params[:more_vendors] ||= false
      params[:page_type] ||= "small_screen"
      params[:is_test] ||= "true"
      params[:show_list] ||= ["All","widget-1", "ad-300", "ad-120", "ad-728"]
    end
    render :layout => false
  end

  def index
    redirect_to advertisements_demo_path
  end

  def demo
    params[:ref_url] ||= "http://gadgetstouse.com/full-reviews/gionee-elife-e6-review/11205"
    params[:ads_id] ||= 3
    params[:more_vendors] ||= false
    params[:is_test] ||= "true"
    render :layout => false
  end

  def vendor_demo
    params[:ref_url] ||= ""
    params[:page_type] ||= "type_1"
    params[:ads_id] ||= 3
    params[:more_vendors] ||= false
    params[:is_test] ||= "true"
    params[:item_id] ||= "13789,9955,9921,15452,16559"
    render :layout => false
  end

  def amazon_demo
    params[:ref_url] ||= ""
    params[:page_type] ||= "type_4"
    params[:ads_id] ||= 12
    params[:more_vendors] ||= false
    params[:is_test] ||= "true"
    params[:item_id] ||= "13789,9955,9921,15452,16559"
    render :layout => false
  end

  def amazon_widget
    params[:page_type] ||= "type_1"
    params[:geo] ||= "in"
    params[:ref_url] ||= "http://www.wiseshe.com/2014/11/loreal-paris-colour-riche-lipstick-in-divine-wine-review-swatches.html"
    render :layout => false
  end

  def amazon_sports_widget
    params[:page_type] ||= "type_1"
    #params[:ref_url] ||= "http://www.sportskeeda.com/cricket/england-odi-captain-eoin-morgan-set-to-play-in-2015-ipl-season"
    render :layout => false
  end

  def search_widget_via_iframe
    render :layout => false
  end

  def ad_via_iframe
    render :layout => false
  end

  def ab_test
    params[:ads_id] ||= 0
    # @alternative_list = [['300*250', ["type_1","type_2"]], ["120*600", ["type_1","type_2"]], ["728*90", ["type_1","type_2"]], ["300*600", ["type_1","type_2"]]]
    @alternative_list = Advertisement.get_alternative_list()
    @advertisements = [0] + Advertisement.all.map(&:id)
    key = "ab_test_#{params[:ads_id]}"
    @ab_test_details = $redis.hgetall(key)
    @alternatives = []
    alternatives = @ab_test_details["alternatives"].blank? ? [] : eval(@ab_test_details["alternatives"]).map {|k,v| v.each {|e| @alternatives << "#{k}:#{e}"}}
  end

  def create_ab_settings
    params[:ads_id] ||= 0
    alternatives = params[:alternatives].blank? ? [] : params[:alternatives].delete_if {|_,val| val.count < 2}
    alternatives = {} if params[:ab_test][:enabled] == "false"
    key = "ab_test_#{params[:ads_id]}"
    $redis.hmset(key, "enabled", params[:ab_test][:enabled], "alternatives",  alternatives)
    Rails.cache.clear
    redirect_to "/advertisements/ab_test"
  end

  def check_user_details
    unless params[:user_id].blank?
      begin
        @details = Advertisement.find_user_details(params[:type], params[:user_id])
      rescue Exception => e
        @details = {}
      end
    end
    render :layout => false
  end

  def carwale_demo
    params[:ref_url] ||= ""
    params[:page_type] ||= "type_5"
    params[:ads_id] ||= 41
    params[:more_vendors] ||= "false"
    params[:is_test] ||= "true"
    params[:item_id] ||= "581,582,583,584,585,586"
    render :layout => false
  end

 private

  def create_impression_before_show_ads
    params[:more_vendors] ||= "false"
    params[:ads_id] ||= ""
    params[:item_id] ||= ""
    params[:page_type] ||= ""
    params[:size] ||= ""
    params[:click_url] ||= ""
    params[:r] ||= ""
    params[:a] ||= ""

    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    params[:ref_url] = url

    # params[:protocol_type] ||= ""
    params[:protocol_type] = request.protocol

    params[:size] = params[:size].to_s.gsub("*", "x")
    # check and assign page type if ab_test is enabled
    ab_test_details = $redis.hgetall("ab_test_#{params[:ads_id]}")
    if !ab_test_details.blank? && ab_test_details["enabled"] == "true"
      alternatives = ab_test_details.blank? ? {} : eval(ab_test_details["alternatives"])
      p alternatives
      p params[:size]
      if alternatives.include?(params[:size])
        types = alternatives["#{params[:size]}"]
        p random_val = Random.rand(1..10)
        params[:page_type] = random_val <= 5 ? types[0] : types[1]
      end
    end

    host_name = configatron.hostname.gsub(/(http|https):\/\//, '')
    if params[:item_id].blank?
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("ads_id", "size", "more_vendors", "ref_url", "page_type", "click_url", "protocol_type", "r"))
    else
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("item_id", "ads_id", "size", "more_vendors", "page_type", "click_url", "protocol_type", "r"))
    end

    cache_params = CGI::unescape(cache_params)
    cache_key = "views/#{host_name}/advertisements/show_ads?#{cache_params}"

    if params[:is_test] != "true"
      cache = Rails.cache.read(cache_key)
      unless cache.blank?
        valid_html = cache.match(/plannto-advertisement main_div/).blank? ? false : true
        if valid_html
          url_params = set_cookie_for_temp_user_and_url_params_process(params)
          @cookie_match = CookieMatch.find_user(cookies[:plan_to_temp_user_id]).first
          impression_type = params[:ad_as_widget] == "true" ? "advertisement_widget" : "advertisement"
          item_id = params[:item_ids]
          matched_val = cache.match(/present_item_id=.*#/)
          unless matched_val.blank?
            val = matched_val[0]
            item_id = val.split("=")[1].gsub("#", "")
          end
          @impression_id = Advertisement.create_impression_before_cache(params, request.referer, url_params, cookies[:plan_to_temp_user_id], nil, request.remote_ip, impression_type, item_id, params[:ads_id], true) if params[:is_test] != "true"
          
          if !cache.match(/<img src=\"https:\/\/cm.g.doubleclick.net.*/).blank?
            if (params[:t].to_i == 1)
              if !@cookie_match.blank? && !@cookie_match.google_user_id.blank?
                cache = cache.gsub(/<img src=\"https:\/\/cm.g.doubleclick.net.*/, "<img src='https://www.plannto.com/pixels?google_gid=#{@cookie_match.google_user_id}&source=google&ref_url=#{params[:ref_url]}' />")
              else
                cache = cache.gsub(/<img src=\"https:\/\/cm.g.doubleclick.net.*/, "<img src='https://cm.g.doubleclick.net/pixel?google_nid=plannto&google_cm&ref_url=#{params[:ref_url]}&google_ula=8326120&google_ula=8365600' />")
              end
            else
              #remove 1x1 pixel image
              cache = cache.gsub(/<img src=\"https:\/\/cm.g.doubleclick.net.*/, "")
              cache = cache.gsub(/<img src=\"https:\/\/www.plannto.com.*/, "")
            end
          elsif !cache.match(/<img src=\"https:\/\/www.plannto.com.*/).blank?
            if (params[:t].to_i == 1)
              if  !@cookie_match.blank? && !@cookie_match.google_user_id.blank?
                cache = cache.gsub(/<img src=\"https:\/\/www.plannto.com.*/, "<img src='https://www.plannto.com/pixels?google_gid=#{@cookie_match.google_user_id}&source=google&ref_url=#{params[:ref_url]}' />")
              else
                cache = cache.gsub(/<img src=\"https:\/\/www.plannto.com.*/, "<img src='https://cm.g.doubleclick.net/pixel?google_nid=plannto&google_cm&ref_url=#{params[:ref_url]}&google_ula=8326120&google_ula=8365600' />")
              end
            else
              #remove 1x1 pixel image
              cache = cache.gsub(/<img src=\"https:\/\/cm.g.doubleclick.net.*/, "")
              cache = cache.gsub(/<img src=\"https:\/\/www.plannto.com.*/, "")
            end
          else
            if (params[:t].to_i == 1)
              if  !@cookie_match.blank? && !@cookie_match.google_user_id.blank?
                cache = cache.gsub("</head>", "<img src='https://www.plannto.com/pixels?google_gid=#{@cookie_match.google_user_id}&source=google&ref_url=#{params[:ref_url]}' />\n</head>")
              else
                cache = cache.gsub("</head>", "<img src='https://cm.g.doubleclick.net/pixel?google_nid=plannto&google_cm&ref_url=#{params[:ref_url]}&google_ula=8326120&google_ula=8365600' />\n</head>")
              end
            end
          end

          cache = cache.gsub(/iid=.{36}/, "iid=#{@impression_id}")
          cache.match "sid=#{params[:sid]}\""
          cache = cache.gsub(/sid=\S*\"/, "sid=#{params[:sid]}\"")
        end
        return render :text => cache.html_safe
        # Rails.cache.write(cache_key, cache)
      end
    end
  end


  def create_impression_before_show_video_ads()
    params[:more_vendors] ||= "false"
    params[:ads_id] ||= ""
    params[:item_id] ||= ""
    params[:page_type] ||= ""
    params[:size] ||= ""
    params[:click_url] ||= ""
    params[:r] ||= ""
    params[:a] ||= ""
    params[:type] = "video_advertisement"
    format = request.format.to_s.split("/")[1]
    params[:format] = format

    # params[:protocol_type] ||= ""
    params[:protocol_type] = request.protocol

    params[:size] = params[:size].to_s.gsub("*", "x")

    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)

    url = url.gsub(/(http|https):\/\//, '')

    params[:ref_url] = url
    params[:itemsaccess] = itemsaccess

    url_params = set_cookie_for_temp_user_and_url_params_process(params)
    params[:url_params] = url_params
    params[:plan_to_temp_user_id] = cookies[:plan_to_temp_user_id]

    # check and assign page type if ab_test is enabled
    # ab_test_details = $redis.hgetall("ab_test_#{params[:ads_id]}")
    # if !ab_test_details.blank? && ab_test_details["enabled"] == "true"
    #   alternatives = ab_test_details.blank? ? {} : eval(ab_test_details["alternatives"])
    #   p alternatives
    #   p params[:size]
    #   if alternatives.include?(params[:size])
    #     types = alternatives["#{params[:size]}"]
    #     p random_val = Random.rand(1..10)
    #     params[:page_type] = random_val <= 5 ? types[0] : types[1]
    #   end
    # end

    host_name = configatron.hostname.gsub(/(http|https):\/\//, '')

    # cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("ads_id", "size", "more_vendors", "ref_url", "page_type", "click_url", "protocol_type", "r"))
    cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("ads_id", "size", "item_id", "format", "protocol_type"))

    cache_params = CGI::unescape(cache_params)
    cache_key = "views/#{host_name}/advertisements/video_ads?#{cache_params}.xml"

    if params[:is_test] != "true"
      cache = Rails.cache.read(cache_key)
      unless cache.blank?
        valid_html = cache.match(/VAST/).blank? ? false : true
        if valid_html
          @impression_id = VideoImpression.add_video_impression_to_resque(params, request.remote_ip)

          old_iid = FeedUrl.get_value_from_pattern(cache, "iid=<iid>&amp;", "<iid>")
          cache = cache.gsub(old_iid, @impression_id)

          old_ref_url = FeedUrl.get_value_from_pattern(cache, "ref_url=<ref_url>&amp;", "<ref_url>")
          cache = cache.gsub(old_ref_url, url) if !old_ref_url.blank?
        end
        # set_access_control_headers()
        return render :xml => cache.html_safe
        # Rails.cache.write(cache_key, cache)
      end
    end
  end

  def set_access_control_headers
    uri = URI.parse(request.referer) rescue ""
    headerdetails = "*"
    if (uri != "")
     headerdetails = uri.scheme+ "://" + uri.host
    end
    headers['Access-Control-Allow-Origin'] = headerdetails
    headers['Access-Control-Request-Method'] = headerdetails
    if (headerdetails != "*" && (headerdetails.include? "youtube.com"))
       headers['Access-Control-Allow-Credentials'] = 'true'
    end
  end

end
