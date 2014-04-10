class Vendor < Item
  has_many :vendor_details, :foreign_key => :item_id
  has_many :hotel_vendor_details
 
 def self.get_item_object(item)
    item = item.vendor
 end
end