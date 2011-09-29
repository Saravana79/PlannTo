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

has_many :accessories,
         :through => :itemrelationships
         #:class_name => 'Accessory'
        # :source => :accessory


end
