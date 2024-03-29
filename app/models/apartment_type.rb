class ApartmentType < Item
  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 2.0,  :as => :name_ac do |item|
      tempName = item.name.gsub("-","")
      if (!item.alternative_name.nil?)
        tempName = tempName + " " +item.alternative_name.to_s.gsub("-", "")
      end
      if (!item.hidden_alternative_name.nil?)
        tempName =tempName + " " + item.hidden_alternative_name.to_s.gsub("-", "")
      end
      tempName
    end

    text :nameformlt do |item|
      item.name.to_s.gsub("-", "")
    end

    string :status

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
            hash.merge(attribute_value.attribute.name.parameterize.underscore.to_sym => attribute_value.value)
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
            hash.merge(attribute_value.attribute.name.parameterize.underscore.to_sym => attribute_value.value)
          else
            hash
          end

        end
      end
    end

  end
end