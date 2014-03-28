class State < Item
  has_many :itemrelationships, :foreign_key => :relateditem_id
  has_many :cities, :through => :itemrelationships
  #has_many :related_car_groups, :class_name => 'Itemrelationship', :foreign_key => :relateditem_id
  #has_many :related_cars,   :through => :related_car_groups

end
