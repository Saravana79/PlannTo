class PixelsController < ApplicationController

  before_filter :generate_cookie_if_not_exist

  def index
    if !params[:google_gid].blank? && params[:google_error].blank?
      CookieMatch.enqueue_cookie_matching(params, cookies[:plan_to_temp_user_id])
    end
    head :no_content
  end

  def pixel_matching
    cookie_match = CookieMatch.find_or_initialize_by_plannto_user_id(cookies[:plan_to_temp_user_id])
    cookie_match.update_attributes(:google_user_id => params[:google_gid], :match_source => "google_pixel")

    $redis_rtb.pipelined do
      $redis_rtb.set("cm:#{params[:google_gid]}", cookies[:plan_to_temp_user_id])
      $reids_rtb.expire("cm:#{params[:google_gid]}", 2.weeks)
    end

    redirect_to "http://cm.g.doubleclick.net/pixel?google_nid=plannto&google_push=#{params[:google_push]}"
  end

  private

  def generate_cookie_if_not_exist
    cookies[:plan_to_temp_user_id] = {value: SecureRandom.hex(20), expires: 1.year.from_now} if cookies[:plan_to_temp_user_id].blank?
  end
end
