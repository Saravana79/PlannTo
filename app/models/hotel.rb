class Hotel < Item
  has_one :itemrelationship, :foreign_key => :item_id
  has_one :city, :through => :itemrelationship

end
