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


 def self.search_type(type)
   return [ "ItemtypeTag".camelize.constantize, "AttributeTag".camelize.constantize,"Topic".camelize.constantize,"Manufacturer".camelize.constantize, "CarGroup".camelize.constantize,"Car".camelize.constantize, "Tablet".camelize.constantize, "Mobile".camelize.constantize, "Camera".camelize.constantize,"Bike".camelize.constantize,"Cycle".camelize.constantize] if (type == "" || type == "Others" || type.nil?)
   return type.camelize.constantize
 end

  def self.search_profile_item_type(search_type)
    if search_type == "follower"
      return["AttributeTag".camelize.constantize,"Topic".camelize.constantize,"Car".camelize.constantize, "Tablet".camelize.constantize, "Mobile".camelize.constantize, "Camera".camelize.constantize,"Bike".camelize.constantize,"Cycle".camelize.constantize]
     else  
      return ["Car".camelize.constantize, "Tablet".camelize.constantize, "Mobile".camelize.constantize, "Camera".camelize.constantize,"Bike".camelize.constantize,"Cycle".camelize.constantize]
   end
  end


def self.wizared_search_type(wizared_type)
  if wizared_type == "owner" || wizared_type == "buyer"
     return ["Car".camelize.constantize, "Tablet".camelize.constantize, "Mobile".camelize.constantize, "Camera".camelize.constantize,"Bike".camelize.constantize,"Cycle".camelize.constantize] 
  else
    return ["AttributeTag".camelize.constantize,"Topic".camelize.constantize]
  end      
end

def manu
    self.manufacturer
end

end
