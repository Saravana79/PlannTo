class PixelsController < ApplicationController
  include Admin::AdvertisementsHelper
  # skip_before_filter :cache_follow_items, :store_session_url
  skip_filter *_process_action_callbacks.map(&:filter)
  before_filter :generate_cookie_if_not_exist, :except => [:pixel_matching]

  # cookie matching
  def index
    if !params[:google_gid].blank? && params[:google_error].blank?
      CookieMatch.enqueue_cookie_matching(params, cookies[:plan_to_temp_user_id])
    end
    head :no_content
  end

  def pixel_matching
    google_ula = CookieMatch.enqueue_pixel_matching(params, cookies[:plan_to_temp_user_id])
  #   google_ula = "&google_ula=58712800"
    redirect_val = "https://cm.g.doubleclick.net/pixel?google_nid=plannto&google_push=#{params[:google_push]}" + google_ula
    redirect_to redirect_val
  end

  def conv_track_pixel
    ref_url = request.referer
    req_param = params.reject {|s| ["controller", "action", "ref_url", "callback", "format", "_", "click_url", "hou_dynamic_l", "protocol_type", "price_full_details", "doc_title-undefined", "source_source_url"].include?(s.to_s)}
    url_params = set_cookie_for_temp_user_and_url_params_process(req_param)
    conversion_pixel_detail = ConversionPixelDetail.create(:plannto_user_id => cookies[:plan_to_temp_user_id], :ref_url => ref_url, :source => params[:ref], :conversion_time => Time.now, :params => url_params)
    render :nothing => true
  end


  def vendor_page
    return render :nothing => true
    
    params[:source] ||= "google"
    # ref_url = request.referer
    source_source_url = params[:source_source_url]
    ref_url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    ref_url = ref_url.to_s

    if params[:type].to_s == "conversion"
      @img_src = nil
      req_param = params.reject {|s| ["controller", "action", "ref_url", "callback", "format", "_", "click_url", "hou_dynamic_l", "protocol_type", "price_full_details", "doc_title-undefined", "source_source_url"].include?(s.to_s)}
      url_params = set_cookie_for_temp_user_and_url_params_process(req_param)

      conversion_pixel_detail = ConversionPixelDetail.create(:plannto_user_id => cookies[:plan_to_temp_user_id], :ref_url => ref_url, :source => params[:source], :conversion_time => Time.now, :params => url_params)
    else
      ref_url = CGI.escape(ref_url) if ref_url.to_s.exclude?("%3A%2F%2F")
      if source_source_url.to_s.exclude?("%3A%2F%2F")
        ref_url_params = CookieMatch.get_params(source_source_url)
        source_source_url_domain = ""
        if !ref_url_params.blank?
          source_source_url_domain = ref_url_params["utm_source"].blank? ? "" : ref_url_params["utm_source"][0].to_s
        end
        if !source_source_url_domain.blank?
          source_source_url = source_source_url.split("?")[0].to_s + "?utm_source=#{source_source_url_domain}"
        else
          source_source_url = ""
        end
        source_source_url = CGI.escape(source_source_url)
      end

      if params[:source] != "mysmartprice"

        cookie_match = CookieMatch.find_user_by_source(cookies[:plan_to_temp_user_id], params[:source]).first
        if !cookie_match.blank? && !cookie_match.google_user_id.blank?
          @img_src = "https://www.plannto.com/pixels?google_gid=#{cookie_match.google_user_id}&source=#{params[:source]}&ref_url=#{ref_url}&source_source_url=#{source_source_url}"
        else
          google_ula_vendor = case params[:source]
                                when "mysmartprice"
                                  "&google_ula=8365600"
                                when "housing"
                                  "&google_ula=8423560"
                                when "autoportal"
                                  "&google_ula=389421041"
                                else
                                  ""
                              end

          @img_src = "https://cm.g.doubleclick.net/pixel?google_nid=plannto&google_cm&source=#{params[:source]}&ref_url=#{ref_url}&google_ula=8326120#{google_ula_vendor}&source_source_url=#{source_source_url}"
        end
      else
        @img_src = nil
      end
    end

    respond_to do |format|
      format.js
      format.html { render :json => {} }
    end
  end

  def un_matching_cookie
    user_id = cookies[:plan_to_temp_user_id]
    CookieMatch.un_match_cookie(user_id) unless user_id.blank?
    render :nothing => true
  end

  private

  def generate_cookie_if_not_exist
    if cookies[:plan_to_temp_user_id].blank? && cookies[:plannto_optout].blank?
      cookies[:plan_to_temp_user_id] = {value: SecureRandom.hex(20), expires: 1.year.from_now}
    end
  end
end
