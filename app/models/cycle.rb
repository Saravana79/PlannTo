# To change this template, choose Tools | Templates
# and open the template in the editor.

class Cycle < Product
 
  has_many :compares, :as => :comparable

  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 2.0,  :as => :name_ac do |item|
      item.name.gsub("-","")
    end  
    
    string :name do |item|
      item.name.gsub("-", "")
    end 
    
    string :status
    string :manufacturer, :multiple => true do |product|
      product.manufacturer.name
    end
    integer :orderbyid  do |item|
      item.itemtype.orderby
    end
    float :rating  do |item|
      item.rating
    end
    time :created_at
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
end
