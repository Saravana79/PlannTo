class AddImpression < ActiveRecord::Base

 def self.save_add_impression_data(type,itemid,request_referer,time,user,remote_ip)
   ai = AddImpression.new
   ai.impression_id = nil
   ai.advertisement_type = type
   ai.item_id = itemid
   ai.hosted_site_url = request_referer
   ai.impression_time = time
   ai.user_id = user
   ai.ip_address = remote_ip
   publisher_domain = URI.parse(request_referer).host rescue ""
   publisher = Publisher.where(:publisher_url => publisher_domain).first 
   ai.publisher_id = publisher
   ai.save 
 end
end

