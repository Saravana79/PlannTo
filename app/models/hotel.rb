class Hotel < Item
  has_many :itemrelationships, :foreign_key => :relateditem_id
  #has_many :hotels, :through => :itemrelationships
  #has_many :related_car_groups, :class_name => 'Itemrelationship', :foreign_key => :relateditem_id
  #has_many :related_cars,   :through => :related_car_groups

end
