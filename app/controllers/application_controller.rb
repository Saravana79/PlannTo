class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def user_follow_item    
    Rails.cache.fetch("item_follow"+current_user.id.to_s) { current_user.follows.group_by(&:followable_id) }
  end

  def comparable_items
    @comparable_items = Compare.all(:conditions => { :session_id => session[:current_session_key] }) 
  end

end
