class Country < Item
  has_many :itemrelationships, :foreign_key => :relateditem_id
  has_many :states, :through => :itemrelationships

end
