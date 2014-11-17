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
    redirect_to "http://cm.g.doubleclick.net/pixel?google_nid=plannto&google_push=#{params[:google_push]}"
  end

  private

  def generate_cookie_if_not_exist
    cookies[:plan_to_temp_user_id] = {value: SecureRandom.hex(20), expires: 1.year.from_now} if cookies[:plan_to_temp_user_id].blank?
  end
end
