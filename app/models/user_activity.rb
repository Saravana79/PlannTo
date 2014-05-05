class UserActivity < ActiveRecord::Base
 belongs_to :user
 
 def self.save_user_activity(current_user,related_id,related_activity,related_activity_type,activity_id,remote_ip)
    u = UserActivity.new
    u.user_id = current_user.id
    u.related_id = related_id
    u.related_activity = related_activity
    u.related_activity_type = related_activity_type
    u.time = Time.zone.now
    u.activity_id = activity_id
    u.ip_address = remote_ip
    u.save   
 end
 
  def sort_by
    time
  end
  
  def self.update_user_activity(current_user,content_id,sub_type)
    UserActivity.where('related_activity_type !=? and related_activity_type !=? and related_id =?',"User","Buying Plan",content_id).each do |act|
      act.update_attribute('related_activity_type',sub_type)
    end
 end 
end
