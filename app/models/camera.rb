class Camera < Product

  has_many :compares, :as => :comparable

  searchable :auto_index => true, :auto_remove => true  do
  
    text :name , :boost => 2.0,  :as => :name_ac do |item|
      item.name.gsub("-","")
    end  
    
    string :name do |item|
      item.name.gsub("-", "")
    end 
    string :status
    
    string :alternative_name do |item|
      item.alternative_name.gsub("-", "")  rescue ""
    end  
    
    string :hidden_alternative_name do |item|
      item.hidden_alternative_name.gsub("-", "")  rescue ""
    end
 
    string :manufacturer, :multiple => true do |product|
      product.manufacturer.name rescue ''
    end
    
    float :rating_search_result do |item|
       item_type_id = Itemtype.find_by_itemtype('Camera').id
       avearge_rating_of_average  = ItemRating.find_by_sql("select avg(average_rating) as avg1 from item_ratings where item_id in (select id from items where itemtype_id = #{item_type_id}) and (average_rating is not null  or average_rating!=0)").first.avg1.to_f
      (((item.item_rating.review_count/(item.item_rating.review_count + configatron.rating_m_for_camera.to_i )) * item.item_rating.average_rating.to_f) + ((configatron.rating_m_for_camera.to_i/(item.item_rating.review_count+configatron.rating_m_for_camera.to_i))*avearge_rating_of_average )).to_f rescue 0.0
    end
      
    time :created_at
    date :launch_date do |item|
     if  (item.attribute_values.where(:attribute_id => 8).first.value.nil? rescue true)
       item.created_at
     else
         (item.attribute_values.where(:attribute_id => 8).first.value.to_date rescue item.created_at)
     end
    end    
    
    integer :orderbyid  do |item|
      item.itemtype.orderby
    end
    float :rating  do |item|
      item.rating
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
end
