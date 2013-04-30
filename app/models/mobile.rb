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
    time :created_at
    float :rating_search_result do |item|
       item_type_id = Itemtype.find_by_itemtype('Mobile').id
       avearge_rating_of_average  = ItemRating.find_by_sql("select avg(average_rating) as avg1 from item_ratings where item_id in (select id from items where itemtype_id = #{item_type_id}) and (average_rating is not null  or average_rating!=0)").first.avg1.to_f
      (((item.item_rating.review_count/(item.item_rating.review_count + configatron.rating_m_for_mobile.to_i )) * item.item_rating.average_rating) + ((configatron.rating_m_for_mobile.to_i/(item.item_rating.review_count+configatron.rating_m_for_mobile.to_i))*avearge_rating_of_average )) rescue 0.0
    end
    date :launch_date do |item|
     if (item.attribute_values.where(:attribute_id => 8).first.value.nil? rescue true)
       item.created_at
     else
       (item.attribute_values.where(:attribute_id => 8).first.value.to_date rescue item.created_at)
     end
    end  
      
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
