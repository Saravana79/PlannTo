class AddImpression < ActiveRecord::Base

 def self.save_add_impression_data(type,itemid,request_referer,time,user,remote_ip,impression_id)
   ai = AddImpression.new
   ai.impression_id = impression_id
   ai.advertisement_type = type
   ai.item_id = itemid
   ai.hosted_site_url = request_referer
   ai.impression_time = time
   ai.user_id = user
   ai.ip_address = remote_ip
   publisher_domain = URI.parse(request_referer).host rescue ""
   publisher = Publisher.where(:publisher_url => publisher_domain).first 
   unless publisher.nil?
      ai.publisher_id = publisher.id
   end
   ai.save 
   return ai.id
 end
end

