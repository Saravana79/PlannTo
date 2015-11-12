class PixelsController < ApplicationController

  skip_before_filter :cache_follow_items, :store_session_url
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
    render :nothing => true
  end


  def vendor_page
    params[:source] ||= "google"

    if params[:source] != "mysmartprice" && params[:source] != 'manipal'
      ref_url = request.referer

      @cookie_match = CookieMatch.find_user(cookies[:plan_to_temp_user_id]).first
      if !@cookie_match.blank? && !@cookie_match.google_user_id.blank?
        @img_src = "https://www.plannto.com/pixels?google_gid=#{@cookie_match.google_user_id}&source=#{params[:source]}&ref_url=#{ref_url}"
      else
        google_ula_vendor = case params[:source]
                              when "mysmartprice"
                                "&google_ula=8365600"
                              when "housing"
                                "&google_ula=8423560"
                              when "cardekho"
                                "&google_ula=57128440"
                              else
                                ""
                            end

        @img_src = "https://cm.g.doubleclick.net/pixel?google_nid=plannto&google_cm&source=#{params[:source]}&ref_url=#{ref_url}&google_ula=8326120#{google_ula_vendor}"
      end
    else
      @img_src = nil
      if params[:source] == 'manipal'
         @img_src = "https://www.plannto.com/pixels?source=#{params[:source]}&ref_url=#{ref_url}"
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
