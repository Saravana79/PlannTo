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

 def self.search_type(type)
   return [ "ItemtypeTag".camelize.constantize, "AttributeTag".camelize.constantize,"Manufacturer".camelize.constantize, "CarGroup".camelize.constantize,"Car".camelize.constantize, "Tablet".camelize.constantize, "Mobile".camelize.constantize, "Camera".camelize.constantize,"Bike".camelize.constantize,"Cycle".camelize.constantize] if (type == "" || type == "Others" || type.nil?)
   return type.camelize.constantize
 end



end
