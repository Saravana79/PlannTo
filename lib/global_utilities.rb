

module GlobalUtilities

  def get_item_priority_list(item, variance)
    numeric_hash = Array.new
    boolean_hash = Array.new
    text_hash = Array.new
    itemtype_id = item.itemtype.id
    attribute_ids = AttributesRelationships.where("itemtype_id = #{itemtype_id} and priority = 1").collect(&:attribute_id)
    attribute_values = AttributeValue.where(:attribute_id => attribute_ids, :item_id => item.id)
    # puts "this item has " + "#{attribute_values.size}"
    attribute_values.each do |item_attribute|
      # puts  "#{item_attribute.attribute.name} - #{item_attribute.value}  #{item_attribute.attribute.attribute_type} "

      unless (item_attribute.value == "" || item_attribute.value.nil? || item_attribute.value == "0")
        if item_attribute.attribute.attribute_type == Attribute::NUMERIC
          #puts item_attribute.value
          min_value = lower_search_value(item_attribute.value, variance)
          #puts min_value
          max_value = upper_search_value(item_attribute.value, variance)
          #puts max_value
          numeric_hash << {:attribute_name => item_attribute.attribute.name, :min_value => min_value, :max_value => max_value}
        elsif item_attribute.attribute.attribute_type == Attribute::BOOLEAN
          boolean_hash << {:attribute_name => item_attribute.attribute.name, :value => item_attribute.value}
        elsif item_attribute.attribute.attribute_type == Attribute::TEXT
          text_hash << {:attribute_name => item_attribute.attribute.name.to_sym, :value => item_attribute.value}
        end
      end

    end
    #item.priority_specification.each do |item_attribute|
    #puts  "#{item_attribute.name} - #{item_attribute.value}  #{item_attribute.attribute_type} "
    #  unless (item_attribute.value == "" || item_attribute.value.nil? || item_attribute.value == "0")
    #  if item_attribute.attribute_type == Attribute::NUMERIC
    #puts item_attribute.value
    #    min_value = item_attribute.lower_search_value(variance)
    #puts min_value
    #   max_value = item_attribute.upper_search_value(variance)
    #puts max_value
    #   numeric_hash << {:attribute_name => item_attribute.name, :min_value => min_value, :max_value => max_value}
    # elsif item_attribute.attribute_type == Attribute::BOOLEAN
    #   boolean_hash << {:attribute_name => item_attribute.name, :value => item_attribute.value}
    # elsif item_attribute.attribute_type == Attribute::TEXT
    #    text_hash << {:attribute_name => item_attribute.name.to_sym, :value => item_attribute.value}
    #  end
    #  end
    #end
        
    return {:numeric_hash => numeric_hash, :boolean_hash => boolean_hash, :text_hash => text_hash}  
      
        
  end

  def get_sunspot_related_items(item_type, numeric_hash, boolean_hash, text_hash)
    items =Sunspot.search(item_type.camelize.constantize) do
      keywords "", :fields => :name
      dynamic :features do
        numeric_hash.each do |hash|
          with(hash[:attribute_name].to_sym).greater_than(hash[:min_value])
          with(hash[:attribute_name].to_sym).less_than(hash[:max_value])
        end
      end
      dynamic :features_string do
        text_hash.each do |hash|
          with(hash[:attribute_name].to_sym, hash[:value])
        end
        boolean_hash.each do |hash|
          with(hash[:attribute_name].to_sym, hash[:value])
        end
      end
    end
    return items
  end

  def filter_similar_group_ids(items, item_type, original_item)
    item_ids = Array.new
    items.results.each do |item|
      if item_type == "Car"
        item_ids << item.id unless item.cargroup.id == original_item.cargroup.id
      else
        item_ids << item.id unless item.id == original_item.id
      end
    end
    return item_ids
  end


  def lower_search_value(c_value, variance)
    value = c_value.to_f
    min_value = (value - (value*variance)/100).round(2)
    return min_value.to_f
  end

  def upper_search_value(c_value, variance)
    value = c_value.to_f
    max_value = (value + (value*variance)/100).round(2)
    return max_value.to_f
  end

  def self.get_class_name(class_name)
    parent_class_name = case class_name
    when "VideoContent" then "Content"
    when "ArticleContent" then "Content"
    else class_name
    end
    return parent_class_name
  end
     

end
