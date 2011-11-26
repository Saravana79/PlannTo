# To change this template, choose Tools | Templates
# and open the template in the editor.

class Manufacturer < Item
  has_many :itemrelationships, :foreign_key => :relateditem_id
  has_many :products,
    :through => :itemrelationships
  has_many :related_car_groups, :class_name => 'Itemrelationship', :foreign_key => :relateditem_id
  has_many :car_groups,
    :through => :related_car_groups
  before_save :add_relation_type

  
  def add_relation_type
    self.relationtype = 'Manufacturer'
  end

end
