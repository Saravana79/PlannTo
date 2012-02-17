class ApplicationController < ActionController::Base
  include Authentication
  include Reputation
  protect_from_forgery
  before_filter :check_authentication
  before_filter :store_session_url
  rescue_from FbGraph::Exception, :with => :fb_graph_exception

  def check_authentication
    facebook_current_user
  end

  def facebook_friends
    if current_user && current_user.facebook
      Facebook.store_facebook_users(current_user,facebook_profile)
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def store_session_url
    if current_user.blank?
      session["user_return_to"] = request.env["REQUEST_URI"]
      if request.env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
        session["js_call"] = true
      else
        session["previous_html_url"] = request.env["REQUEST_URI"]
      end
    end
  end

  def after_ajax_call_path_for
    if session["js_call"] && !current_user.blank?
      session["js_call"] = false
      redirect_to session["previous_html_url"] 
    end
  end

  def fb_graph_exception(e)
    flash[:error] = {
      :title   => e.class,
      :message => e.message
    }
    redirect_to root_url
  end

  def all_user_follow_item  
    Rails.cache.fetch("item_follow_"+5.to_s) do
      current_user.follows.group_by(&:followable_id)
    end
  end

  helper_method :user_follow_type

  def user_follow_type(item, user = current_user)
    @user_follow = user.blank? || all_user_follow_item[item.id].blank? ? false : all_user_follow_item[item.id].last
  end

end
