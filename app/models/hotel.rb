class Hotel < Item
  has_one :itemrelationship, :foreign_key => :item_id
  has_one :city, :through => :itemrelationship

  has_many :hotel_vendor_details, :foreign_key => :item_id

end
