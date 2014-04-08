class City < Item
  has_one :itemrelationship, :foreign_key => :item_id
  has_one :state, :through => :itemrelationship

  has_many :itemrelationships, :foreign_key => :relateditem_id
  has_many :hotels, :through => :itemrelationships

end
