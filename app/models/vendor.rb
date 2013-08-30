class Vendor < ActiveRecord::Base

 def rating
   ItemRating.where(:item_id => self.id).first.average_rating rescue 0.0 
 end
 
 def self.get_item_object(item)
    vendor = Vendor.find(item.site)
    Item.where(:id => vendor.item_id).first rescue ""
 end
end
