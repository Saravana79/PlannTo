class PixelsController < ApplicationController

  before_filter :generate_cookie_if_not_exist

  def index
    if !params[:google_gid].blank? && params[:google_error].blank?
      CookieMatch.enqueue_cookie_matching(params, cookies[:plan_to_temp_user_id])
    end
    head :no_content
  end

  def pixel_matching
    CookieMatch.enqueue_pixel_matching(params, cookies[:plan_to_temp_user_id])
    redirect_to "https://cm.g.doubleclick.net/pixel?google_nid=plannto&google_push=#{params[:google_push]}"
  end

  def vendor_page
    @cookie_match = CookieMatch.find_user(cookies[:plan_to_temp_user_id]).last
    ref_url = request.referer
    if !@cookie_match.blank? && !@cookie_match.google_user_id.blank?
      @img_src = "https://www.plannto.com/pixels?google_gid=#{@cookie_match.google_user_id}&source=mysmartprice&ref_url=#{ref_url} width=1px height=1px"
    else
      @img_src = "https://cm.g.doubleclick.net/pixel?google_nid=plannto&google_cm&source=mysmartprice&ref_url=#{ref_url} width=1px height=1px"
    end

    respond_to do |format|
      format.js
      format.html { render :json => {} }
    end
  end

  private

  def generate_cookie_if_not_exist
    cookies[:plan_to_temp_user_id] = {value: SecureRandom.hex(20), expires: 1.year.from_now} if cookies[:plan_to_temp_user_id].blank?
  end
end
