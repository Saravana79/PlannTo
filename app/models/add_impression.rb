class AddImpression < ActiveRecord::Base
 belongs_to :user
 belongs_to :item
 def self.save_add_impression_data(type,itemid,request_referer,time,user,remote_ip,impression_id,itemsaccess=nil,params=nil)
   ai = AddImpression.new
   ai.impression_id = impression_id
   ai.advertisement_type = type
   ai.item_id = itemid
   ai.hosted_site_url = request_referer
   ai.impression_time = time
   ai.user_id = user.id
   ai.ip_address = remote_ip
   ai.itemsaccess = itemsaccess
   ai.params = params
   publisher = Publisher.getpublisherfromdomain(request_referer)
   unless publisher.nil?
      ai.publisher_id = publisher.id
   end
   ai.save 
   return ai.id
 end
end

