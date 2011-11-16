# To change this template, choose Tools | Templates
# and open the template in the editor.

class Car < Product
#  has_many :itemrelationships, :foreign_key => :item_id
#  has_many :relatedcars,
#    :through => :itemrelationships, :include => :cargroup

  has_many :compares, :as => :comparable
  acts_as_taggable
  #  acts_as_taggable_on :product
  acts_as_commentable

  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 4.0,  :as => :name_ac
    string :manufacturer, :multiple => true do |product|
      product.manufacturer.name
    end
    string :cargroup, :multiple => true do |product|
      product.cargroup.name
    end
      
    dynamic_float :features do |car|
      car.attribute_values.inject({}) do |hash,attribute_value|
        if attribute_value.attribute.attribute_type == "Numeric"
          hash.merge(attribute_value.attribute.name.to_sym => attribute_value.value)
        else
          hash
        end
      end
    end
    
    dynamic_string :features_string do |car|
      car.attribute_values.inject({}) do |hash,attribute_value|
        #if attribute_value.attribute.attribute_type == "Text"
        if attribute_value.attribute.attribute_type != "Numeric"
          hash.merge(attribute_value.attribute.name.to_sym => attribute_value.value)
        else
          hash
        end
      end
    end
  end

  def add_to_compare
    "Add to Compare"
  end
  
end
