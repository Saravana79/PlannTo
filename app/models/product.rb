# To change this template, choose Tools | Templates
# and open the template in the editor.

class Product < Item


has_one :itemrelationship, :foreign_key => :item_id
has_many :itemrelationships, :foreign_key => :item_id

has_one :manufacturer,
        :through => :itemrelationship
#        :conditions => {'relationtype' => 'Manufacturer'}
#        :class_name => 'Manufacturer',
#        :source => :manufacturer
has_one :cargroup, :through => :itemrelationship, :source => :cargroup

has_many :accessories,
         :through => :itemrelationships
         #:class_name => 'Accessory'
        # :source => :accessory
        

  
def priority_specification
  specification.where(:priority => 1)
end

def specification
  item_attributes.select("value, name, unit_of_measure, category_name")
end

end
