class AdvertisementsController < ApplicationController
  include Admin::AdvertisementsHelper
  layout "product"

  # before_filter :create_impression_before_show_ads, :only => [:show_ads], :if => proc { |c| !request.xhr? }
  # caches_action :show_ads, :cache_path => proc {|c|  params[:item_id].blank? ? params.slice("ads_id", "size", "more_vendors", "ref_url") : params.slice("item_id", "ads_id", "size", "more_vendors") }, :expires_in => 2.hours, :if => proc { |s| !request.xhr? }
  skip_before_filter :cache_follow_items, :store_session_url, :only => [:show_ads]
  def show_ads
    #TODO: everything is clickable is only updated for type1 have to update for type2
    impression_type, url, url_params, itemsaccess, vendor_ids, ad_id, winning_price_enc = check_and_assigns_ad_default_values()
    sid = params[:sid]

    @ad_template_type = "type_2" if @suitable_ui_size == 120

    return static_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid) if !@ad.blank? && (@ad.advertisement_type == "static" || @ad.advertisement_type == "flash")

    p_item_ids = item_ids = []
    p_item_ids = item_ids = params[:item_id].split(",") unless params[:item_id].blank?
    @items, itemsaccess, url = Item.get_items_by_item_ids(item_ids, url, itemsaccess, request)

    return show_plannto_ads() if !@ad.blank? && @ad.advertisement_type == "plannto"

    status, @displaycount, @activate_tab = set_status_and_display_count(@moredetails, @activate_tab)
    publisher = Publisher.getpublisherfromdomain(url)
    vendor_ids = Vendor.get_vendor_ids_by_publisher(publisher, vendor_ids) if params[:more_vendors] == "true"

    item_ids = @items.map(&:id)

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
      @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids.first, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                                              cookies[:plan_to_temp_user_id], ad_id, winning_price_enc, sid) if @is_test != "true"
      @item_details = @item_details.uniq(&:url)
      @item_details, @sliced_item_details, @item, @items = Item.assign_template_and_item(@ad_template_type, @item_details, @items)
      @click_url = params[:click_url] =~ URI::regexp ? params[:click_url] : ""
    end

    respond_to do |format|
      format.json {
        if @item_details.blank?
          render :json => {:success => false, :html => ""}, :callback => params[:callback]
        else
          render :json => {:success => @item_details.blank? ? false : true, :html => render_to_string("advertisements/show_ads.html.erb", :layout => false)}, :callback => params[:callback]
        end
      }
      format.html { render :layout => false }
    end
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
    @vendor_ids = params[:more_vendors] == "true" ? [9861, 9882, 9874, 9880, 9856] : []
    @ref_url = params[:ref_url] ||= ""
    @iframe_width, @iframe_height = params[:size].split("*")
    @suitable_ui_size = Advertisement.process_size(@iframe_width)
    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    @ad = Advertisement.get_ad_by_id(params[:ads_id]).first
    url_params = set_cookie_for_temp_user_and_url_params_process(params)
    vendor_ids, ad_id, @ad_template_type = assign_ad_and_vendor_id(@ad, @vendor_ids)
    winning_price_enc = params[:wp]
    return impression_type, url, url_params, itemsaccess, vendor_ids, ad_id, winning_price_enc
  end

  def static_ad_process(impression_type, url, itemsaccess, url_params, winning_price_enc, sid)
    # static ad process
    @publisher = Publisher.getpublisherfromdomain(@ad.click_url)

    @image = @ad.images.first

    @impression_id = AddImpression.add_impression_to_resque(impression_type, nil, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id, winning_price_enc, sid) if @is_test != "true"

    respond_to do |format|
      format.json {
        return render :json => {:success => true, :html => render_to_string("advertisements/show_static_ads.html.erb", :layout => false)}, :callback => params[:callback]
      }
      format.html { return render "show_static_ads.html.erb", :layout => false }
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

  def search_widget_via_iframe
    render :layout => false
  end

  def ad_via_iframe
    render :layout => false
  end

 private

  def create_impression_before_show_ads
    host_name = APP_URL.gsub(/(http|https):\/\//, '')
    if params[:item_id].blank?
      cache_key = "views/#{host_name}/advertisements/show_ads?ads_id=#{params[:ads_id]}&more_vendors=#{params[:more_vendors]}&ref_url=#{params[:ref_url]}&size=#{params[:size]}"
    else
      cache_key = "views/#{host_name}/advertisements/show_ads?ads_id=#{params[:ads_id]}&item_id=#{params[:item_id]}&more_vendors=#{params[:more_vendors]}&size=#{params[:size]}"
    end

    logger.info cache_key
    cache = Rails.cache.read(cache_key)
    unless cache.blank?
      url_params = set_cookie_for_temp_user_and_url_params_process(params)
      @impression_id = Advertisement.create_impression_for_show_ads(params, request.referer, url_params, cookies[:plan_to_temp_user_id], nil, request.remote_ip)

      cache = cache.gsub(/iid=\S+&/, "iid=#{@impression_id}&")
      Rails.cache.write(cache_key, cache)
    end
  end

end
