class ApplicationController < ActionController::Base
  include Authentication
  include Reputation
  protect_from_forgery
  before_filter :check_authentication

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


  def user_follow_type
    @user_follow = current_user.blank? || all_user_follow_item[@item.id].blank? ? false : all_user_follow_item[@item.id].last
  end

end
