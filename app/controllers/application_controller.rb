class ApplicationController < ActionController::Base
  include Authentication
  include Reputation
  protect_from_forgery
  before_filter :check_authentication
  before_filter :store_session_url
  rescue_from FbGraph::Exception, :with => :fb_graph_exception

  before_filter :cache_follow_items 

  def cache_follow_items
    user = current_user
    if user
      user.set_user_follow_item
    else
      false
    end
  end
   
  def set_access_control_headers
     headers['Access-Control-Allow-Origin'] = '*'
     headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
     headers['Access-Control-Max-Age'] = '1000'
     headers['Access-Control-Allow-Headers'] = '*,X-Requested-With'
  end
  
  def cors_preflight_check
    if request.method == :options
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end
  
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

  def all_user_follow_item(item_id = params[:id])
    current_user.get_user_follow_item(item_id)
  end

  helper_method :user_follow_type

  def user_follow_type(item, user = current_user)
    user_follow_items = all_user_follow_item(item.id)
    user.blank? || user_follow_items.blank? ? false : user_follow_items
  end
end
