# To change this template, choose Tools | Templates
# and open the template in the editor.

class Car < Product
  has_many :itemrelationships, :foreign_key => :item_id
  has_many :relatedcars,
    :through => :itemrelationships, :include => :cargroup
  acts_as_taggable
  #  acts_as_taggable_on :product
  acts_as_commentable
  
  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 4.0,  :as => :name_ac
    string :manufacturer do |product|
      product.manufacturer.name
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
        if attribute_value.attribute.attribute_type == "Text"
          hash.merge(attribute_value.attribute.name.to_sym => attribute_value.value)
        else
          hash
        end
      end
    end
  end

  def plan_to_buy
    "Plan to buy"
  end

  def own_a_item
    "I Own it"
  end

  def follow_this_item
    "Follow This Car"
  end

  
end
