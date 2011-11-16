class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def all_user_follow_item
    Rails.cache.fetch("item_follow_"+current_user.id.to_s) do
      current_user.follows.group_by(&:followable_id)
    end
  end


  def user_follow_type    
    @user_follow = current_user.blank? || user_follow_item[@item.id].blank? ? false : user_follow_item[@item.id].last
  end

end
