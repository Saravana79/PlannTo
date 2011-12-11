class ApplicationController < ActionController::Base
  include Authentication
  protect_from_forgery
#  before_filter :check_authentication
  rescue_from FbGraph::Exception, :with => :fb_graph_exception

  def check_authentication
    begin
      auth = Facebook.auth.from_cookie(cookies)
      authenticate Facebook.identify(auth.user)
    rescue
      return false
    end
  end

  def fb_graph_exception(e)
    flash[:error] = {
      :title   => e.class,
      :message => e.message
    }
    current_user.try(:destroy)
    redirect_to root_url
  end

  def all_user_follow_item
    Rails.cache.fetch("item_follow_"+current_user.id.to_s) do
      current_user.follows.group_by(&:followable_id)
    end
  end


  def user_follow_type    
    @user_follow = current_user.blank? || all_user_follow_item[@item.id].blank? ? false : all_user_follow_item[@item.id].last
  end

end
