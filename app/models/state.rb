class State < Item
  has_one :itemrelationship, :foreign_key => :item_id
  has_many :itemrelationships, :foreign_key => :relateditem_id

  has_one :country, :through => :itemrelationship
  has_many :cities, :through => :itemrelationships

end
