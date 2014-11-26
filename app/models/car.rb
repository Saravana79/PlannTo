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

    
    string :manufacturer, :multiple => true do |product|
      product.manufacturer.name rescue ''
    end
    
    string :status
    float :rating  do |item|
      item.rating
    end
     
    float :rating_search_result do |item|
     if !(item.item_rating.nil?)
      if !((item.item_rating.average_rating.to_i == 0 or item.item_rating.average_rating.nil? or item.item_rating.average_rating.blank?))
          item.item_rating.final_rating
      end
     end 
  end  
    
     time :created_at
    date :launch_date do |item|
     valuetemp = item.attribute_values.where(:attribute_id => 8).first.value rescue ""
     if (valuetemp.nil? or valuetemp == ""  rescue true)
       item.created_at
     else
         (Date.parse(valuetemp) rescue item.created_at)
     end
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
          elsif attribute_value.attribute.attribute_type == "Rating"
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
          if (attribute_value.attribute.attribute_type != "Numeric" or  attribute_value.attribute.attribute_type != "Rating")
            hash.merge(attribute_value.attribute.name.parameterize.underscore.to_sym => attribute_value.value)
          else
            hash
          end

        end
      end
    end
  end

  def unfollowing_related_items(user, number)
    if user
      relateditems.select{|item| !user.following?(item) }[0..number]
    else
      relateditems.limit(number)
    end
  end

  def add_to_compare
    "Add to Compare"
  end
  
end
