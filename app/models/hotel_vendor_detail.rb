class HotelVendorDetail < ActiveRecord::Base
  # has_one :vendor, :primary_key => "vendor_id", :foreign_key => "id"
  belongs_to :hotel, :foreign_key => :item_id
  belongs_to :vendor
end
