# To change this template, choose Tools | Templates
# and open the template in the editor.

class Mobile < Product
#  has_many :itemrelationships, :foreign_key => :item_id
#  has_many :relatedcars,
#    :through => :itemrelationships, :include => :cargroup
  acts_as_taggable
  #  acts_as_taggable_on :product
  acts_as_commentable
  
  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 2.0,  :as => :name_ac do |item|
      item.name.gsub("_","")
    end 
    string :name do |item|
      item.name.gsub("_", " ")
    end 
    string :status
    string :manufacturer, :multiple => true do |product|
      product.manufacturer.name.gsub("_", " ")
    end
    time :created_at
    float :rating  do |item|
      item.rating
    end
    integer :orderbyid  do |item|
      item.itemtype.orderby
    end
    dynamic_float :features do |car|
      car.attribute_values.inject({}) do |hash,attribute_value|
        if attribute_value.attribute.search_display_attributes.nil?
          hash
        else
          if attribute_value.attribute.attribute_type == "Numeric"
            hash.merge(attribute_value.attribute.name.to_sym => attribute_value.value)
          else
            hash
          end
        end
      end
    end

    dynamic_string :features_string do |car|
      car.attribute_values.inject({}) do |hash,attribute_value|
        if attribute_value.attribute.search_display_attributes.nil?
          hash
        else
          if attribute_value.attribute.attribute_type != "Numeric"
            hash.merge(attribute_value.attribute.name.to_sym => attribute_value.value)
          else
            hash
          end

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
