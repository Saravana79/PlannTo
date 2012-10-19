class UserActivity < ActiveRecord::Base
 belongs_to :user
 def self.save_user_activity(current_user,related_id,related_activity,related_activity_type)
    u = UserActivity.new
    u.user_id = current_user.id
    u.related_id = related_id
    u.related_activity = related_activity
    u.related_activity_type = related_activity_type
    u.time = Time.now
    u.save   
 end
end
