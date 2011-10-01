# To change this template, choose Tools | Templates
# and open the template in the editor.

class Car < Product
  has_many :itemrelationships, :foreign_key => :item_id
  has_many :relatedcars,
           :through => :itemrelationships
  acts_as_taggable
#  acts_as_taggable_on :product
  acts_as_commentable
  
    searchable :auto_index => true, :auto_remove => true  do
      string :manufacturer do |product|
        product.manufacturer.name    
      end 
      dynamic_string :features do |car|
        car.attribute_values.inject({}) do |hash,attribute_value|
          hash.merge(attribute_value.attribute.name.to_sym => attribute_value.value)
        end
      end
    end
  
  
end
