class AddImpression < ActiveRecord::Base
 belongs_to :user
 belongs_to :item
 def self.save_add_impression_data(type,itemid,request_referer,time,user,remote_ip,impression_id,itemsaccess=nil,params=nil, temp_user_id)
   ai = AddImpression.find_by_impression_id_and_advertisement_type_and_item_id_and_hosted_site_url_and_temp_user_id(impression_id, type, itemid, request_referer, temp_user_id )
   unless ai
      ai = AddImpression.new
      ai.impression_id = impression_id
      ai.advertisement_type = type
      ai.item_id = itemid
      ai.hosted_site_url = request_referer
      ai.impression_time = time
      unless user.nil?
         ai.user_id = user.id
      end
      ai.temp_user_id = temp_user_id
      ai.ip_address = remote_ip
      ai.itemsaccess = itemsaccess
      ai.params = params
      publisher = Publisher.getpublisherfromdomain(request_referer)
      unless publisher.nil?
         ai.publisher_id = publisher.id
      end
      ai.save 
   end
   return ai.id
 end
end

