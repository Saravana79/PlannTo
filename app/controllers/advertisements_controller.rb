class AdvertisementsController < ApplicationController
  include Admin::AdvertisementsHelper
  layout "product"

  before_filter :create_impression_before_show_ads, :only => [:show_ads], :if => lambda { request.format.html? }
  caches_action :show_ads, :cache_path => proc {|c|  params[:item_id].blank? ? params.slice("ads_id", "size", "more_vendors", "ref_url", "page_type", "protocol_type", "r", "fashion_id", "ad_type", "hou_dynamic_l") : params.slice("item_id", "ads_id", "size", "more_vendors", "page_type", "protocol_type", "r", "fashion_id", "ad_type", "hou_dynamic_l") }, :expires_in => 2.hours, :if => lambda { request.format.html? && params[:is_test] != "true" }

  before_filter :create_impression_before_image_show_ads, :only => [:image_show_ads]#, :if => lambda { request.format.html? }
  caches_action :image_show_ads, :cache_path => proc {|c|  params[:item_id].blank? ? params.slice("ads_id", "ref_url", "protocol_type", "format", "ad_type", "nv_click_url", "ev_click_url", "expand_type", "need_close_btn", "viewable", "expand_on") : params.slice("item_id", "ads_id", "protocol_type", "format", "ad_type", "nv_click_url", "ev_click_url", "expand_type", "need_close_btn", "viewable", "expand_on") }, :expires_in => 2.hours, :if => lambda { params[:is_test] != "true" }

  before_filter :create_impression_before_show_video_ads, :only => [:video_ads]
  before_filter :set_access_control_headers, :only => [:video_ads, :video_ad_tracking, :ads_visited, :image_show_ads]
  caches_action :video_ads, :cache_path => proc {|c| params.slice("item_id", "ads_id", "size", "format") }, :expires_in => 2.hours, :if => lambda { params[:is_test] != "true" }

  skip_before_filter :cache_follow_items, :store_session_url, :only => [:show_ads, :video_ads, :ads_visited, :image_show_ads]
  skip_before_filter  :verify_authenticity_token, :only => [:ads_visited]
  #after_filter :set_access_control_headers, :only => [:video_ads, :video_ad_tracking]
  def show_ads
    #TODO: everything is clickable is only updated for type1 have to update for type2
    impression_type, url, url_params, itemsaccess, vendor_ids, ad_id, winning_price_enc = check_and_assigns_ad_default_values()
    return_path = "advertisements/show_ads.html.erb"
    @sid = sid = params[:sid] ||= ""

    # TODO: hot coded values, have to change in feature

    if @suitable_ui_size == "120" && params[:page_type] != "type_4" && params[:page_type] != "type_6"
      @ad_template_type = ad_id == 21 ? "type_3" : "type_2"
    end

    @ad_template_type = params[:page_type] unless params[:page_type].blank?

    # params[:page_type] = @ad_template_type
    #
    # url_params = Advertisement.make_url_params(params)

    p_item_ids = item_ids = []
    p_item_ids = item_ids = params[:item_id].to_s.split(",") unless params[:item_id].blank?

    if !@ad.blank? && (@ad.advertisement_type == "fashion" || params[:ad_type] == "fashion")
      return fashion_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, params[:item_id], vendor_ids)
    elsif !@ad.blank? && (@ad.advertisement_type == "jockey_fashion" || params[:ad_type] == "jockey_fashion")
      return jockey_fashion_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, params[:item_id], vendor_ids)
    elsif !@ad.blank? && @ad.id == 52
      return junglee_used_car_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, params[:item_id], vendor_ids)
    elsif !@ad.blank? && @ad.id == 56
      return amazon_deal_ads(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, params[:item_id], vendor_ids, return_path)
    elsif !@ad.blank? && (@ad.advertisement_type == "static" || @ad.advertisement_type == "flash")
      return static_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, item_ids)
    # elsif !@ad.blank? && @ad.id == 24
    #   return show_ad_layout(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, item_ids)
    elsif !@ad.blank? && @ad.advertisement_type == "housing_dynamic"
      return housing_dynamic_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, item_ids)
    end

    # sort_disable = params[:r].to_i == 1 ? "true" : "false"
    sort_disable = "false"

    if item_ids.include?(configatron.root_level_laptop_id.to_s)
      original_ids = $redis.get("amazon_top_laptops").to_s.split(",")
      @items = original_ids.blank? ? [] : Item.where(:id => original_ids)
    elsif item_ids.include?(configatron.root_level_television_id.to_s)
      original_ids = $redis.get("amazon_top_televisions").to_s.split(",")
      @items = original_ids.blank? ? [] : Item.where(:id => original_ids)
    elsif !@ad.blank? && @ad.id == 52
      # Nothing
    elsif !@ad.blank? && @ad.having_related_items == true
      itemsaccess = "advertisement"
      original_ids = @ad.get_item_ids_from_ads(url)
      @items = original_ids.blank? ? [] : Item.where(:id => original_ids)
    else
      @items, itemsaccess, url = Item.get_items_by_item_ids(item_ids, url, itemsaccess, request, false, sort_disable)
    end

    return show_plannto_ads() if !@ad.blank? && @ad.advertisement_type == "plannto"

    status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
    @publisher = Publisher.getpublisherfromdomain(url)

    #TODO: temp commented no one is using now
    # vendor_ids = Vendor.get_vendor_ids_by_publisher(publisher, vendor_ids) if params[:more_vendors] == "true"

    item_ids = @items.blank? ? [] : @items.map(&:id)
    @item = @items.first

    @item_details = Itemdetail.get_item_details_by_item_ids_count(item_ids, vendor_ids, @items, @publisher, status, params[:more_vendors], p_item_ids, @ad)

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
      @vendor_ad_details.default = {"vendor_name" => "Amazon"}
      if @is_test != "true"
        @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids.first, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], ad_id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
        Advertisement.check_and_update_act_spent_budget_in_redis(ad_id, winning_price_enc)
      end

      @item_details = @item_details.uniq(&:url)
      @item_details, @sliced_item_details, @item, @items = Item.assign_template_and_item(@ad_template_type, @item_details, @items, @suitable_ui_size)
      if (@suitable_ui_size == "300_600" && @item_details.count < 3)
        old_item_details = @item_details

        # if @ad_template_type == "type_5"
        #   new_item_ids = Item.get_carwale_item_ids_for_300_600()
        # else
        #   new_item_ids = Item.get_item_ids_for_300_600()
        # end
        new_item_ids = Item.get_item_ids_for_300_600()
        @item_details = Itemdetail.get_item_details_by_item_ids_count(new_item_ids, vendor_ids, @items=[], @publisher, status, params[:more_vendors], p_item_ids, @ad)
        @item_details = old_item_details + @item_details
        @item_details, @sliced_item_details, @item, @items = Item.assign_template_and_item(@ad_template_type, @item_details, @items=[], @suitable_ui_size)
      end
      if @suitable_ui_size == "300_600" && params[:page_type] == "type_2"
        @ad_template_type = ad_id == 21 ? "type_3" : "type_1"
      end
      @click_url = params[:click_url] =~ URI::regexp ? params[:click_url] : ""
      @click_url = @click_url.gsub("&amp;", "&")
    end
    @vendor_detail = @ad.vendor.vendor_detail rescue VendorDetail.new

    respond_to do |format|
      format.json {
        if @item_details.blank?
          render :json => {:success => false, :html => ""}, :callback => params[:callback]
        else
          render :json => {:success => @item_details.blank? ? false : true, :html => render_to_string(return_path, :layout => false)}, :callback => params[:callback]
          # render :json => {:success => @item_details.blank? ? false : true, :html => render_to_string(return_path, :layout => false)}.to_json
        end
      }
      format.html {
        if @item_details.blank?
          render :nothing => true
        else
          render return_path, :layout => false
        end
      }
    end
  end

  def image_show_ads
    if !@ad.blank?
      #TODO: everything is clickable is only updated for type1 have to update for type2
      impression_type, url, url_params, itemsaccess, vendor_ids, ad_id, winning_price_enc = check_and_assigns_ad_default_values()
      @sid = sid = params[:sid] ||= ""
      # @item_details = []

      # TODO: hot coded values, have to change in feature
      if @suitable_ui_size == "120" && params[:page_type] != "type_4" && params[:page_type] != "type_6"
        @ad_template_type = ad_id == 21 ? "type_3" : "type_2"
      end

      @ad_template_type = params[:page_type] unless params[:page_type].blank?

      p_item_ids = item_ids = []
      p_item_ids = item_ids = params[:item_id].to_s.split(",") unless params[:item_id].blank?

      # sort_disable = params[:r].to_i == 1 ? "true" : "false"
      sort_disable = "false"

      if (params[:expanded].to_i == 1)
        return return_expanded_html()
        return_exp_path = ""
      else
        return_exp_path = "advertisements/image_overlay_ads_expanded_div.html.erb"

        @ad_video_detail = @ad.ad_video_detail
        expanded = params[:expanded].to_s
        # AddImpression.add_impression_to_update_visible(params[:impression_id], "", expanded)
      end

      if !@adv_detail.blank? && @adv_detail.ad_type == "dynamic"
        @normal_view_ratio = 0.0
        @items, itemsaccess, url = Item.get_items_by_item_ids(item_ids, url, itemsaccess, request, false, sort_disable)

        included_beauty = @items.map {|d| d.is_a?(Beauty) || d.is_a?(Apparel)}.include?(true) rescue false

        if included_beauty
          get_details_from_beauty_items(url, itemsaccess, impression_type, ad_id, winning_price_enc, sid)
        else
          status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
          @publisher = Publisher.getpublisherfromdomain(url) if @publisher.blank?

          #TODO: temp commented no one is using now
          # vendor_ids = Vendor.get_vendor_ids_by_publisher(publisher, vendor_ids) if params[:more_vendors] == "true"

          item_ids = @items.blank? ? [] : @items.map(&:id)
          @item = @items.first

          @item_details = Itemdetail.get_item_details_by_item_ids_count(item_ids, vendor_ids, @items, @publisher, status, params[:more_vendors], p_item_ids, @ad)

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
            @vendor_ad_details.default = {"vendor_name" => "Amazon"}

            @item_details = @item_details.uniq(&:url)
            @item_details, @sliced_item_details, @item, @items = Item.assign_template_and_item(@ad_template_type, @item_details, @items, @suitable_ui_size)
            if (@suitable_ui_size == "300_600" && @item_details.count < 3)
              old_item_details = @item_details

              # if @ad_template_type == "type_5"
              #   new_item_ids = Item.get_carwale_item_ids_for_300_600()
              # else
              #   new_item_ids = Item.get_item_ids_for_300_600()
              # end
              new_item_ids = Item.get_item_ids_for_300_600()
              @item_details = Itemdetail.get_item_details_by_item_ids_count(new_item_ids, vendor_ids, @items=[], @publisher, status, params[:more_vendors], p_item_ids, @ad)
              @item_details = old_item_details + @item_details
              @item_details, @sliced_item_details, @item, @items = Item.assign_template_and_item(@ad_template_type, @item_details, @items=[], @suitable_ui_size)
            end
            if @suitable_ui_size == "300_600" && params[:page_type] == "type_2"
              @ad_template_type = ad_id == 21 ? "type_3" : "type_1"
            end
            @click_url = params[:click_url] =~ URI::regexp ? params[:click_url] : ""
            @click_url = @click_url.gsub("&amp;", "&")
          end
          @vendor_detail = @ad.vendor.vendor_detail rescue VendorDetail.new

          return_path = "advertisements/show_ads.html.erb"

          @item_details = @item_details.first(6)
        end
      end

      # return_path = "advertisements/show_image_overlay_ads.html.erb"
      return_path = "advertisements/image_overlay_ads_normal_div.html.erb"
      @iframe_width = params[:width].blank? ? "" : params[:width] if @iframe_width.blank?
      @iframe_height = params[:height].blank? ? "" : params[:height] if @iframe_height.blank?

      @iframe_height = @adv_detail.dynamic_ad_height.to_i == 0 ? 162 : @adv_detail.dynamic_ad_height.to_i if !@adv_detail.blank? && @adv_detail.ad_type == "dynamic"

      @ad_template_type = "type_1"
      @vendor_ad_details = vendor_ids.blank? ? {} : VendorDetail.get_vendor_ad_details(vendor_ids)
      @vendor_ad_details.default = {"vendor_name" => "Amazon"}

      if @normal_view_ratio.to_f != 0.0 && !@iframe_width.blank?
        @iframe_height = (@iframe_width.to_f / @normal_view_ratio).to_s
      end

      if @expanded_view_ratio.to_f != 0.0 && !@iframe_exp_width.blank?
        @iframe_exp_height = (@iframe_exp_width.to_f / @expanded_view_ratio).to_s
      end

      @item_type = "mobile"

      if (!@item.blank? && ["Beauty", "Apparel"].include?(@item.type))
        @item_type = "beauty"
      end

      @expand_type = @adv_detail.expand_type.to_s rescue "none"

      if !@adv_detail.blank? && @adv_detail.ad_type == "dynamic"
        @expanded_view_ratio = 0.0
      end

      # if @is_test != "true"
      #   @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids.first, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
      #                                                           cookies[:plan_to_temp_user_id], ad_id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id], params[:visited])
      #   Advertisement.check_and_update_act_spent_budget_in_redis(ad_id, winning_price_enc)
      # end

      if @is_test != "true"
        item_id = @item.id rescue item_ids.first
        @impression_id = AddImpression.add_impression_to_resque(impression_type, item_id, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                                cookies[:plan_to_temp_user_id], ad_id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id], params[:visited])
        Advertisement.check_and_update_act_spent_budget_in_redis(ad_id, winning_price_enc)
      end
    end

    respond_to do |format|
      format.json {
        if @ad.blank? || (@item_details.blank? && included_beauty == false && 1 != 1) #TODO: temp check
          render :json => {:success => false, :html => ""}, :callback => params[:callback]
        else
          # render :json => {:success => @item_details.blank? ? false : true, :html => render_to_string(return_path, :layout => false)}, :callback => params[:callback]
          render :json => {:success => true, :n_ad_height => @iframe_height.to_f, :e_ad_height => @iframe_exp_height.to_f, :expand_type => @expand_type, :need_close_btn => @adv_detail.need_close_btn, :expand_on => @adv_detail.expand_on.to_s, :viewable => @adv_detail.viewable, :html => render_to_string(return_path, :layout => false), :expanded_html => render_to_string(return_exp_path, :layout => false), :impression_id => @impression_id}.to_json
        end
      }
      format.html {
        if @ad.blank? || (@item_details.blank? && included_beauty == false && 1 != 1) #TODO: temp check
          render :nothing => true
        else
          render return_path, :layout => false
        end
      }
    end
  end

  def return_expanded_html()
    return_path = "advertisements/image_overlay_ads_expanded_div.html.erb"

    @ad_video_detail = @ad.ad_video_detail
    expanded = params[:expanded].to_s
    AddImpression.add_impression_to_update_visible(params[:impression_id], "", expanded)

    # expanded_html = render_to_string(return_path, :layout => false)

    respond_to do |format|
      format.json {
        render :json => {:success => true, :html => render_to_string(return_path, :layout => false)}.to_json
      }
      format.html {
        render return_path, :layout => false
      }
    end
  end

  def get_details_from_beauty_items(url, itemsaccess, impression_type, ad_id, winning_price_enc, sid)
    if !@items.blank?
      @item, @items, @search_url, @extra_items = Item.get_item_items_from_amazon(@items, params[:item_ids], params[:page_type], params[:geo])

      if @items.blank?
        @item, @items, @search_url, @extra_items = Item.get_best_seller_beauty_items_from_amazon(params[:page_type], url, params[:geo])
      end
    else
      @item, @items, @search_url, @extra_items = Item.get_best_seller_beauty_items_from_amazon(params[:page_type], url, params[:geo])
      @impression = ImpressionMissing.create_or_update_impression_missing(url, impression_type)
    end

    @search_url = CGI.escape(@search_url)
    url_params = Advertisement.make_url_params(params)

    # include pre order status if we show more details.
    unless @items.blank?
      status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
      @publisher = Publisher.getpublisherfromdomain(url)
      # Check have to activate tabs for publisher or not
      # @activate_tab = true if (@publisher.blank? || (!@publisher.blank? && @active_tabs_for_publisher.include?(@publisher.id)))

      @show_count = Item.get_show_item_count(@items)
    else
      @where_to_buy_items =[]
      itemsaccess = "none"
      @impression = ImpressionMissing.create_or_update_impression_missing(url, impression_type)
    end
    @ref_url = url
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
    @vendor_ids = params[:vendor_ids].to_s.split(",")
    @ref_url = params[:ref_url] ||= ""
    @iframe_width, @iframe_height = params[:size].to_s.split("x")

    ratio = 970.to_f/@iframe_width.to_f
    @ad_height = 400/ratio

    if(!params[:exp_size].nil?)
      @iframe_exp_width, @iframe_exp_height = params[:exp_size].split("x")
    end
    @suitable_ui_size = Advertisement.process_size(@iframe_width, @iframe_height)
    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    @ref_url = url
    # @ad = Advertisement.get_ad_by_id(params[:ads_id]).first

    # @cookie_match = CookieMatch.find_user(cookies[:plan_to_temp_user_id]).first
    vendor_ids, ad_id, @ad_template_type = assign_ad_and_vendor_id(@ad, @vendor_ids)
    url_params = set_cookie_for_temp_user_and_url_params_process(params)
    winning_price_enc = params[:wp]
    return impression_type, url, url_params, itemsaccess, vendor_ids, ad_id, winning_price_enc
  end

  def static_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, item_ids=[])
    # static ad process
    @publisher = Publisher.getpublisherfromdomain(@ad.click_url)

    @image = @ad.images.where(:ad_size => params[:size]).first

    @image = @ad.images.first if @image.blank?

    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids.first, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
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

    # @vendor = Vendor.where(:name => "Amazon").first
    # vendor_ids = [@vendor.id]
    @vendor_image_url = configatron.root_image_url + "vendor/medium/default_vendor.jpeg"
    @vendor_ad_details = vendor_ids.blank? ? {} : VendorDetail.get_vendor_ad_details(vendor_ids)
    @vendor_ad_details.default = {"vendor_name" => "Amazon"}

    @current_vendor = @vendor_ad_details[@ad.vendor_id]
    @vendor_detail = @ad.vendor.vendor_detail rescue VendorDetail.new
    @current_vendor = {} if @current_vendor.blank?
    item_ids = item_id.to_s.split(",")

    @item, @item_details = Item.get_item_and_item_details_from_fashion_url(url, item_ids, vendor_ids, params[:fashion_id], @ad)
    @sliced_item_details = @item_details.each_slice(3)

    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids.first, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
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

  def jockey_fashion_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, item_id, vendor_ids)
    # static ad process
    @publisher = Publisher.getpublisherfromdomain(@ad.click_url)

    @ad_template_type = "type_1" #TODO: only accept type 1

    # @vendor = Vendor.where(:name => "Amazon").first
    # vendor_ids = [@vendor.id]
    @vendor_image_url = configatron.root_image_url + "vendor/medium/default_vendor.jpeg"
    @vendor_ad_details = vendor_ids.blank? ? {} : VendorDetail.get_vendor_ad_details(vendor_ids)
    @vendor_ad_details.default = {"vendor_name" => "Jockey"}

    @current_vendor = @vendor_ad_details[@ad.vendor_id]
    @vendor_detail = @ad.vendor.vendor_detail rescue VendorDetail.new
    @current_vendor = {} if @current_vendor.blank?
    item_ids = item_id.to_s.split(",")

    @item, @item_details = Item.get_item_and_item_details_from_jockey_fashion_url(url, item_ids, vendor_ids, params[:fashion_id], @ad)
    @sliced_item_details = @item_details.each_slice(3)

    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids.first, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
      Advertisement.check_and_update_act_spent_budget_in_redis(@ad.id, winning_price_enc)
    end

    @click_url = params[:click_url] =~ URI::regexp ? params[:click_url] : ""
    @click_url = @click_url.gsub("&amp;", "&")

    respond_to do |format|
      format.json {
        return render :json => {:success => true, :html => render_to_string("advertisements/show_jockey_fashion_ads.html.erb", :layout => false)}, :callback => params[:callback]
      }
      format.html { return render "show_jockey_fashion_ads.html.erb", :layout => false }
    end
  end

  def junglee_used_car_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, item_id, vendor_ids)
    # static ad process
    @publisher = Publisher.getpublisherfromdomain(@ad.click_url)

    @ad_template_type = "type_4" #TODO: only accept type 1

    # @vendor = Vendor.where(:name => "Amazon").first
    # vendor_ids = [@vendor.id]
    @vendor_image_url = configatron.root_image_url + "vendor/medium/default_vendor.jpeg"
    @vendor_ad_details = vendor_ids.blank? ? {} : VendorDetail.get_vendor_ad_details(vendor_ids)
    @vendor_ad_details.default = {"vendor_name" => "Amazon"}

    @current_vendor = @vendor_ad_details[@ad.vendor_id]
    @vendor_detail = @ad.vendor.vendor_detail rescue VendorDetail.new
    @current_vendor = {} if @current_vendor.blank?
    item_ids = item_id.to_s.split(",")

    # @item, @item_details = Item.get_item_and_item_details_from_fashion_url(url, item_ids, vendor_ids, params[:fashion_id])
    @items, @item_details, @item = ItemDetailOther.get_item_detail_others_from_items_and_fashion_id(params[:item_id], params[:fashion_id])

    @item_details, @sliced_item_details, @item, @items = Item.assign_template_and_item(@ad_template_type, @item_details, [@item], @suitable_ui_size,true)

    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids.first, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
      Advertisement.check_and_update_act_spent_budget_in_redis(@ad.id, winning_price_enc)
    end

    @click_url = params[:click_url] =~ URI::regexp ? params[:click_url] : ""
    @click_url = @click_url.gsub("&amp;", "&")

    respond_to do |format|
      format.json {
        return render :json => {:success => true, :html => render_to_string("advertisements/show_junglee_car_ads.html.erb", :layout => false)}, :callback => params[:callback]
      }
      format.html { return render "show_junglee_car_ads.html.erb", :layout => false }
    end
  end

  def amazon_deal_ads(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, item_id, vendor_ids, return_path)
    @item_details = DealItem.get_deal_item_based_on_hour(params[:fashion_id])
    @item_details = Itemdetail.convert_to_itemdetails(@item_details)

    @vendor_ad_details = vendor_ids.blank? ? {} : VendorDetail.get_vendor_ad_details(vendor_ids)
    @vendor_ad_details.default = {"vendor_name" => "Amazon"}
    @item = Item.new
    @vendor_detail = @ad.vendor.vendor_detail rescue VendorDetail.new

    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, item_id, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
      Advertisement.check_and_update_act_spent_budget_in_redis(@ad.id, winning_price_enc)
    end

    render return_path, :layout => false
  end

  def housing_dynamic_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, item_ids)
    @city = Item.get_city_from_item_or_location(item_ids, params[:l])

    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids.first, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
      Advertisement.check_and_update_act_spent_budget_in_redis(@ad.id, winning_price_enc)
    end

    @click_enc_url = configatron.hostname + "/plannto/housing_ad_click?ads_id=#{@ad.id}&iid=#{@impression_id}"
    @click_enc_url = CGI.escape(@click_enc_url)

    respond_to do |format|
      format.json {
        return render :json => {:success => true, :html => render_to_string("advertisements/show_housing_dynamic_ads.html.erb", :layout => false)}, :callback => params[:callback]
      }
      format.html { return render "show_housing_dynamic_ads.html.erb", :layout => false }
    end
  end

  def show_ad_layout(impression_type, url, itemsaccess, url_params, winning_price_enc, sid, item_ids=[])
    # static ad process
    params[:only_layout] = "true"
    @publisher = Publisher.getpublisherfromdomain(@ad.click_url)

    if @is_test != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids.first, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id, winning_price_enc, sid, params[:t], params[:r], params[:a], params[:video], params[:video_impression_id])
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

  def junglee_gadget_demo
    params[:ref_url] ||= "http://gadgetstouse.com/comparison/samsung-galaxy-s4-vs-galaxy-s5-specification-comparison/15912"
    params[:page_type] ||= "type_1"
    params[:ads_id] ||= 51
    params[:more_vendors] ||= false
    params[:is_test] ||= "true"
    params[:item_id] ||= ""
    render :layout => false
  end

  def junglee_used_car_demo
    params[:ref_url] ||= ""
    params[:page_type] ||= "type_1"
    params[:ads_id] ||= 52
    params[:more_vendors] ||= false
    params[:is_test] ||= "true"
    params[:city_id] ||= "29673"
    params[:car_ids] ||= "581,582,583,584,585,586"
    item_ids = params[:city_id].to_s.split(",") + params[:car_ids].to_s.split(",")
    item_ids = item_ids.compact.uniq.join(",")
    params[:item_id] = item_ids
    params[:item_id]
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
    if params[:page_type] == "type_5" && params[:item_id].blank?
      params[:item_id] = "B00AXWKTR4"
    end
    #params[:ref_url] ||= "http://www.sportskeeda.com/cricket/england-odi-captain-eoin-morgan-set-to-play-in-2015-ipl-season"
    render :layout => false
  end

  def search_widget_via_iframe
    render :layout => false
  end

  def elec_widget_demo
    params[:ref_url] ||= "http://indiatoday.intoday.in/technology/story/samsung-galaxy-note-edge-review/1/420649.html"
    params[:type] ||= "elec_widget"
    render :layout => false
  end

  def women_widget_demo
    params[:ref_url] ||= "http://www.wiseshe.com/2014/12/how-to-make-your-curls-last-long.html"
    params[:page_type] ||= "type_1"
    params[:type] ||= "elec_widget"
    render :layout => false
  end

  def price_widget_demo
    params[:ref_url] ||= "http://www.bgr.in/gadgets/mobile-phones/xiaomi/mi-4i-limited-edition-32-gb"
    render :layout => false
  end

  def in_image_ads
    params[:type] ||= ""
    params[:ref_url] ||= "http://wonderwoman.intoday.in/story/5-make-up-tricks-to-hide-visible-signs-of-ageing/1/121454.html"
    render :layout => false
  end

  def in_image_ads_demo
    params[:type] ||= "flash"
    params[:ref_url] ||= "http://wonderwoman.intoday.in/story/5-make-up-tricks-to-hide-visible-signs-of-ageing/1/121454.html"
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

  def paytm_demo
    params[:ref_url] ||= ""
    params[:page_type] ||= "type_6"
    params[:ads_id] ||= 70
    params[:more_vendors] ||= "false"
    params[:is_test] ||= "true"
    params[:item_id] ||= "19673,22889,22890,22892,22893,22894"
    render :layout => false
  end

  def newcar_demo
    params[:ref_url] ||= ""
    params[:page_type] ||= "type_5"
    params[:ads_id] ||= 41
    params[:more_vendors] ||= "false"
    params[:is_test] ||= "true"
    params[:item_id] ||= "581,582,583,584,585,586"
    render "carwale_demo.html.erb", :layout => false
  end

  def gaadi_demo
    params[:ref_url] ||= ""
    params[:page_type] ||= "type_5"
    params[:ads_id] ||= 45
    params[:more_vendors] ||= "false"
    params[:is_test] ||= "true"
    params[:item_id] ||= "581,582,583,584,585,586"
    render :layout => false
  end

  def fashion_demo
    params[:ref_url] ||= ""
    params[:page_type] ||= "type_1"
    params[:ads_id] ||= 40
    params[:more_vendors] ||= "false"
    params[:is_test] ||= "true"
    params[:item_id] ||= ""
    render :layout => false
  end

  def junglee_fashion_demo
    params[:ref_url] ||= ""
    params[:page_type] ||= "type_1"
    params[:ads_id] ||= 47
    params[:more_vendors] ||= "false"
    params[:is_test] ||= "true"
    params[:item_id] ||= "72274"
    render :layout => false
  end

  def inline_ads
    item_names = Item.find_item_names_from_url(params[:url])
  end

  def ads_visited
    visited = params[:visited].to_s
    expanded = params[:expanded].to_s
    AddImpression.add_impression_to_update_visible(params[:impression_id], visited, expanded)
    render :nothing => true
  end

 private

  def create_impression_before_show_ads
    params[:more_vendors] ||= "false"
    params[:ads_id] ||= ""
    params[:item_id] ||= ""
    params[:item_id] = params[:item_id].to_s.split(",").map(&:to_i).sort.join(",") if !params[:item_id].blank?
    params[:page_type] ||= ""
    params[:size] ||= ""
    params[:click_url] ||= ""
    params[:r] ||= ""
    params[:a] ||= ""
    params[:fashion_id] ||= ""
    params[:vendor_ids] ||= ""
    params[:ad_type] ||= ""
    params[:hou_dynamic_l] ||= ""
    params[:l] ||= ""

    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    params[:ref_url] = url

    # params[:protocol_type] ||= ""
    params[:protocol_type] = request.protocol

    @ad = Advertisement.where(:id => params[:ads_id]).first

    if !@ad.blank? && !@ad.template_type.blank? && params[:page_type].blank?
      params[:page_type] = @ad.template_type
    end

    if !@ad.blank? && @ad.advertisement_type == "housing_dynamic"
      params[:hou_dynamic_l] = "l_#{params[:l]}"
    end

    if (params[:item_id].blank? || params[:fashion_id].blank? || (!@ad.blank? && @ad.sort_type == "random"))
      if (!@ad.blank? && ((@ad.id != 52 && @ad.advertisement_type == "fashion") || @ad.sort_type == "random"))
        # item_id, random_id = Item.get_item_id_and_random_id(@ad, params[:item_id])
        #
        # if random_id.blank?
        #   item_id, random_id = Item.get_item_id_and_random_id(@ad, params[:item_id])
        # end

        random_id = rand(20)

        # params[:item_id] = item_id
        params[:fashion_id] = random_id
      end
    end

    if !params[:item_id].blank? && params[:fashion_id].blank?
      if !@ad.blank? && @ad.id == 52
        random_id = rand(10)

        params[:fashion_id] = random_id
      end
    end

    if !@ad.blank? && @ad.id == 56
      random_id = rand(10)

      params[:fashion_id] = random_id
    end

    params[:size] = params[:size].to_s.gsub("*", "x")
    # check and assign page type if ab_test is enabled
    ab_test_details = $redis.hgetall("ab_test_#{params[:ads_id]}")
    if !ab_test_details.blank? && ab_test_details["enabled"] == "true"
      alternatives = ab_test_details.blank? ? {} : eval(ab_test_details["alternatives"])
      if alternatives.include?(params[:size])
        types = alternatives["#{params[:size]}"]
        random_val = Random.rand(1..10)
        params[:page_type] = random_val <= 5 ? types[0] : types[1]
      end
    end

    host_name = configatron.hostname.gsub(/(http|https):\/\//, '')
    if params[:item_id].blank?
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("ads_id", "size", "more_vendors", "ref_url", "page_type", "protocol_type", "r", "fashion_id", "ad_type", "hou_dynamic_l"))
    else
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("item_id", "ads_id", "size", "more_vendors", "page_type", "protocol_type", "r", "fashion_id", "ad_type", "hou_dynamic_l"))
    end

    cache_params = CGI::unescape(cache_params)

    cache_key = "views/#{host_name}/advertisements/show_ads?#{cache_params}"

    # p cache_key

    if params[:is_test] != "true"
      cache = Rails.cache.read(cache_key)

      unless cache.blank?
        valid_html = cache.match(/_blank/).blank? ? false : true
        if valid_html
          url_params = set_cookie_for_temp_user_and_url_params_process(params)
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
              @cookie_match = CookieMatch.find_user(cookies[:plan_to_temp_user_id]).first
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
              @cookie_match = CookieMatch.find_user(cookies[:plan_to_temp_user_id]).first
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
              @cookie_match = CookieMatch.find_user(cookies[:plan_to_temp_user_id]).first
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

          begin
            click_url = params[:click_url]
            new_click_url = FeedUrl.get_value_from_pattern(click_url, "http://adclick.g.doubleclick.net/aclk?<click_params>adurl", "<click_params>")

            old_click_url = FeedUrl.get_value_from_pattern(cache, "http://adclick.g.doubleclick.net/aclk?<click_params>adurl", "<click_params>")
            cache = cache.gsub(old_click_url, new_click_url) if !old_click_url.blank? && !new_click_url.blank?

            new_ref_url = CGI.escape(params[:ref_url].to_s)

            old_ref_url = FeedUrl.get_value_from_pattern(cache, "ref_url=<ref_url>&amp;", "<ref_url>")
            cache = cache.gsub(old_ref_url, new_ref_url)
          rescue Exception => e
            p "Problem in changing click_url and ref_url"
          end
        end
        p "*************************** Cache process success ***************************"
        logger.info "*************************** Cache process success ***************************"

        return render :text => cache.html_safe
        # Rails.cache.write(cache_key, cache)
      end
    end
  end

  def create_impression_before_image_show_ads
    params[:more_vendors] ||= "false"
    params[:ads_id] ||= ""
    params[:item_id] ||= ""
    params[:item_id] = params[:item_id].to_s.split(",").map(&:to_i).sort.join(",") if !params[:item_id].blank?
    params[:page_type] ||= ""
    params[:size] ||= ""
    params[:click_url] ||= ""
    params[:r] ||= ""
    params[:a] ||= ""
    params[:fashion_id] ||= ""
    params[:vendor_ids] ||= ""
    params[:hou_dynamic_l] ||= ""
    params[:l] ||= ""
    params[:visited] ||= ""
    format = request.format.to_s.split("/")[1]
    params[:format] = format
    params[:expand_type] ||= ""
    params[:ad_type] ||= ""
    params[:viewable] ||= ""
    params[:nv_click_url] ||= ""
    params[:ev_click_url] ||= ""
    params[:expand_on] ||= ""
    params[:need_close_btn] ||= ""

    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    params[:ref_url] = url

    @ad = Advertisement.get_ad_from_ref_url_for_image_ads(params)

    #TODO: temporary changes
    # params[:ref_url] = "http://wonderwoman.intoday.in/story/5-make-up-tricks-to-hide-visible-signs-of-ageing/1/121454.html"  #TODO: temp check
    # @ad = Advertisement.find 7
    #
    # params[:protocol_type] ||= ""
    params[:protocol_type] = request.protocol

    @publisher = Publisher.where(:id => params[:publisher_id]).last if !params[:publisher_id].blank?

    # @ad = Advertisement.where(:id => params[:ads_id]).first

    if !@ad.blank?
      params[:ads_id] = @ad.id
      @normal_view_src, @normal_view_src_2, @normal_view_type, @normal_view_ratio = @ad.get_file_based_on_type("normal_view")
      @expanded_view_src, @expanded_view_src_2, @expanded_view_type, @expanded_view_ratio = @ad.get_file_based_on_type("expanded_view")
      # @expanded_file = @ad.images.where(:ad_size => "expanded_view").last
    end

    @adv_detail = !@ad.blank? ? @ad.adv_detail : AdvDetail.new
    if @adv_detail.blank?
      @adv_detail = AdvDetail.new
    else
      params[:ad_type] = @adv_detail.ad_type.to_s
      params[:nv_click_url] = @adv_detail.nv_click_url.to_s
      params[:ev_click_url] = @adv_detail.ev_click_url.to_s
      params[:expand_type] = @adv_detail.expand_type.to_s
      params[:need_close_btn] = @adv_detail.need_close_btn.to_s
      params[:viewable] = @adv_detail.viewable.to_s
      params[:expand_on] = @adv_detail.expand_on
      params[:visited] = @adv_detail.viewable
    end

    if !@ad.blank? && @ad.advertisement_type == "housing_dynamic"
      params[:hou_dynamic_l] = "l_#{params[:l]}"
    end

    if (params[:item_id].blank? || params[:fashion_id].blank? || (!@ad.blank? && @ad.sort_type == "random"))
      if (!@ad.blank? && ((@ad.id != 52 && @ad.advertisement_type == "fashion") || @ad.sort_type == "random"))
        # item_id, random_id = Item.get_item_id_and_random_id(@ad, params[:item_id])
        #
        # if random_id.blank?
        #   item_id, random_id = Item.get_item_id_and_random_id(@ad, params[:item_id])
        # end

        random_id = rand(20)

        # params[:item_id] = item_id
        params[:fashion_id] = random_id
      end
    end

    if !params[:item_id].blank? && params[:fashion_id].blank?
      if !@ad.blank? && @ad.id == 52
        random_id = rand(10)

        params[:fashion_id] = random_id
      end
    end

    params[:size] = params[:size].to_s.gsub("*", "x")
    params[:exp_size] = params[:exp_size].to_s.gsub("*", "x")
    # check and assign page type if ab_test is enabled
    ab_test_details = $redis.hgetall("ab_test_#{params[:ads_id]}")
    if !ab_test_details.blank? && ab_test_details["enabled"] == "true"
      alternatives = ab_test_details.blank? ? {} : eval(ab_test_details["alternatives"])
      if alternatives.include?(params[:size])
        types = alternatives["#{params[:size]}"]
        random_val = Random.rand(1..10)
        params[:page_type] = random_val <= 5 ? types[0] : types[1]
      end
    end

    host_name = configatron.hostname.gsub(/(http|https):\/\//, '')
    if params[:item_id].blank?
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("ads_id", "ref_url", "protocol_type", "format", "ad_type", "nv_click_url", "ev_click_url", "expand_type", "need_close_btn", "viewable", "expand_on"))
    else
      cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("item_id", "ads_id", "protocol_type", "format", "ad_type", "nv_click_url", "ev_click_url", "expand_type", "need_close_btn", "viewable", "expand_on"))
    end

    cache_params = CGI::unescape(cache_params)

    cache_key = "views/#{host_name}/advertisements/image_show_ads?#{cache_params}"
    if params[:format].to_s == "json"
      cache_key = "views/#{host_name}/advertisements/image_show_ads?#{cache_params}.json"
    end

    # p cache_key
    cache_json = {}
    if params[:is_test] != "true"
      cache = Rails.cache.read(cache_key)
      # p JSON.parse(cache)
      unless cache.blank?
        cache_json = JSON.parse(cache)
        valid_html = cache_json["success"]
        cache_html = cache_json["html"].to_s
        if valid_html
          if params[:expanded].blank?
            url_params = set_cookie_for_temp_user_and_url_params_process(params)
            impression_type = params[:ad_as_widget] == "true" ? "advertisement_widget" : "advertisement"
            item_id = params[:item_ids]
            matched_val = cache.match(/present_item_id=.*#/)
            unless matched_val.blank?
              val = matched_val[0]
              item_id = val.split("=")[1].gsub("#", "")
            end
            @impression_id = Advertisement.create_impression_before_cache(params, request.referer, url_params, cookies[:plan_to_temp_user_id], nil, request.remote_ip, impression_type, item_id, params[:ads_id], true) if params[:is_test] != "true"

            cache_json["impression_id"] = @impression_id

            if !cache_html.match(/<img src=\"https:\/\/cm.g.doubleclick.net.*/).blank?
              if (params[:t].to_i == 1)
                @cookie_match = CookieMatch.find_user(cookies[:plan_to_temp_user_id]).first
                if !@cookie_match.blank? && !@cookie_match.google_user_id.blank?
                  cache_html = cache_html.gsub(/<img src=\"https:\/\/cm.g.doubleclick.net.*/, "<img src='https://www.plannto.com/pixels?google_gid=#{@cookie_match.google_user_id}&source=google&ref_url=#{params[:ref_url]}' />")
                else
                  cache_html = cache_html.gsub(/<img src=\"https:\/\/cm.g.doubleclick.net.*/, "<img src='https://cm.g.doubleclick.net/pixel?google_nid=plannto&google_cm&ref_url=#{params[:ref_url]}&google_ula=8326120&google_ula=8365600' />")
                end
              else
                #remove 1x1 pixel image
                cache_html = cache_html.gsub(/<img src=\"https:\/\/cm.g.doubleclick.net.*/, "")
                cache_html = cache_html.gsub(/<img src=\"https:\/\/www.plannto.com.*/, "")
              end
            elsif !cache_html.match(/<img src=\"https:\/\/www.plannto.com.*/).blank?
              if (params[:t].to_i == 1)
                @cookie_match = CookieMatch.find_user(cookies[:plan_to_temp_user_id]).first
                if  !@cookie_match.blank? && !@cookie_match.google_user_id.blank?
                  cache_html = cache_html.gsub(/<img src=\"https:\/\/www.plannto.com.*/, "<img src='https://www.plannto.com/pixels?google_gid=#{@cookie_match.google_user_id}&source=google&ref_url=#{params[:ref_url]}' />")
                else
                  cache_html = cache_html.gsub(/<img src=\"https:\/\/www.plannto.com.*/, "<img src='https://cm.g.doubleclick.net/pixel?google_nid=plannto&google_cm&ref_url=#{params[:ref_url]}&google_ula=8326120&google_ula=8365600' />")
                end
              else
                #remove 1x1 pixel image
                cache_html = cache_html.gsub(/<img src=\"https:\/\/cm.g.doubleclick.net.*/, "")
                cache_html = cache_html.gsub(/<img src=\"https:\/\/www.plannto.com.*/, "")
              end
            else
              if (params[:t].to_i == 1)
                @cookie_match = CookieMatch.find_user(cookies[:plan_to_temp_user_id]).first
                if  !@cookie_match.blank? && !@cookie_match.google_user_id.blank?
                  cache_html = cache_html.gsub("</head>", "<img src='https://www.plannto.com/pixels?google_gid=#{@cookie_match.google_user_id}&source=google&ref_url=#{params[:ref_url]}' />\n</head>")
                else
                  cache_html = cache_html.gsub("</head>", "<img src='https://cm.g.doubleclick.net/pixel?google_nid=plannto&google_cm&ref_url=#{params[:ref_url]}&google_ula=8326120&google_ula=8365600' />\n</head>")
                end
              end
            end

            cache_html = cache_html.gsub(/iid=.{36}/, "iid=#{@impression_id}")
            cache_html.match "sid=#{params[:sid]}\""
            cache_html = cache_html.gsub(/sid=\S*\"/, "sid=#{params[:sid]}\"")
            cache_json["html"] = cache_html
          else
            cache_json["html"] = cache_html
          end
        end
        p "*************************** Cache process success ***************************"
        logger.info "*************************** Cache process success ***************************"
        
        set_access_control_headers()
        if params[:format].to_s == "json"
          return render :json => cache_json.to_json
        else
          return render :text => cache.html_safe
        end
        cache_json.clear
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

    # cache_params = ActiveSupport::Cache.expand_cache_key(params.slice("ads_id", "size", "more_vendors", "ref_url", "page_type", "protocol_type", "r"))
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
    if !uri.blank?
     headerdetails = uri.scheme+ "://" + uri.host rescue "*"
    end
    headers['Access-Control-Allow-Origin'] = headerdetails
    headers['Access-Control-Request-Method'] = headerdetails
    if (headerdetails != "*" && (headerdetails.include? "youtube.com"))
       headers['Access-Control-Allow-Credentials'] = 'true'
    end
  end

end
