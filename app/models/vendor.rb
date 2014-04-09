class Vendor < Item
  has_many :vendor_details, :foreign_key => :item_id
 
 def self.get_item_object(item)
    item = item.vendor
 end
end