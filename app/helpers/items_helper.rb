module ItemsHelper

  def display_specifications(item)
    # specifications = item.priority_specification.collect{|item_attribute|
    #   "#{item_attribute.name} - #{item_attribute.value} ( #{item_attribute.unit_of_measure} )"
    #   }
    specifications = Array.new
    item.priority_specification.each do |item_attribute|
      content = get_content(item_attribute)
      specifications << content if content != ""
    end
    specifications.to_sentence
  end

  def display_specification?(item)
    return true unless (item.value == "" || item.value.nil? || item.value == "0")
    return false
  end

  def display_items_specifications(items)
    display_items = Array.new
    items.each do |item|
      display_item = Hash.new
      count = 1
      item.specification.group_by(&:category_name).each do |category, product_attributes|
        display_item = display_item.merge!({:category_name => category})
        product_attributes.each do |product_attribute|
          display_items << display_item.merge!({"#{product_attribute.name}_#{count}".to_sym => display_specification_value(product_attribute)})
        end
      end

    end
  end

  def attribute_display_required?(ids, attribute_id)
    attribute_values = AttributeValue.where("item_id in (?) and attribute_id =?", ids, attribute_id)
    return true if attribute_values.size > 0
    return false
  end

  def group_display_required?(attribute_ids, item_ids)
    return false if attribute_ids.size == 0
    attribute_values = AttributeValue.where("item_id IN (?) and attribute_id IN (?)", item_ids, attribute_ids)
    return true if attribute_values.size > 0
    return false
  end

  def show_item_value(item, attribute)
    compare_item = AttributeValue.find_by_item_id_and_attribute_id( item.id, attribute.id) #.include(:attribute).select("value, name, unit_of_measure, category_name, attribute_type")
    return "" if compare_item.nil?
    value = display_specification_value(compare_item, attribute)
    return value
  end

  def display_specification_value(item, attribute="")
    attribute = item if attribute == ""
    content = ""
    if attribute.attribute_type == Attribute::TEXT
      content = "#{item.value}"
    elsif attribute.attribute_type == Attribute::BOOLEAN
      if item.value == "True"
        content = "<img src='/images/check.png' width='12' height='12'>"
      else
        content = "<img src='/images/close.png' width='12' height='12'>"
      end
    elsif attribute.attribute_type == Attribute::NUMERIC
      if (attribute.unit_of_measure == "GB" && item.value.to_f < 1)
        value = convert_to_MB(item.value.to_f)
        content = "#{value} MB" if value != 0
      elsif (attribute.unit_of_measure == "MB" && item.value.to_f >= 1024)
        value = convert_to_GB(item.value.to_f)
        content = "#{value} GB" if value != 0
      elsif (attribute.unit_of_measure == "GHz" && item.value.to_f < 1)
        value = convert_to_MHz(item.value.to_f)
        content = "#{value} MHz" if value != 0
      elsif (attribute.unit_of_measure == "MHz" && item.value.to_f >= 1000)
        value = convert_to_GHz(item.value.to_f)
        content = "#{value} GHz" if value != 0
      else
        content += "#{item.value}"
        unless (attribute.unit_of_measure == "" || attribute.unit_of_measure.nil?)
          content += "  #{attribute.unit_of_measure}"
        end
      end
    else
      content = "#{item.value}"
      unless (attribute.unit_of_measure == "" || attribute.unit_of_measure.nil?)
        content += "  #{attribute.unit_of_measure}"
      end
    end
    return content
  end

  def get_content(item)
    content = ""   
    unless (item.value == "" || item.value.nil? || item.value == "0")
      if item.attribute_type == Attribute::TEXT
        content = "#{item.value}"
      elsif item.attribute_type == Attribute::BOOLEAN       
        if item.value == "True"
          content = "Has #{item.name}"
        end
      elsif item.attribute_type == Attribute::NUMERIC
        if (item.unit_of_measure == "GB" && item.value.to_f < 1)
          value = convert_to_MB(item.value.to_f)
          content = "#{item.name} - #{value} MB" if value != 0
        elsif (item.unit_of_measure == "MB" && item.value.to_f >= 1024)
          value = convert_to_GB(item.value.to_f)
          content = "#{item.name} - #{value} GB" if value != 0
        elsif (item.unit_of_measure == "GHz" && item.value.to_f < 1)
          value = convert_to_MHz(item.value.to_f)
          content = "#{item.name} - #{value} MHz" if value != 0
        elsif (item.unit_of_measure == "MHz" && item.value.to_f >= 1000)
          value = convert_to_GHz(item.value.to_f)
          content = "#{item.name} - #{value} GHz" if value != 0
        else
          content += "#{item.name} - #{item.value}"
          unless (item.unit_of_measure == "" || item.unit_of_measure.nil?)
            content += "  #{item.unit_of_measure}"
          end
        end
      else
        content = "#{item.name} - #{item.value}"
        unless (item.unit_of_measure == "" || item.unit_of_measure.nil?)
          content += "  #{item.unit_of_measure}"
        end
      end
    end

    return content
  end

  def convert_to_MB(value)   
    converted_value = value*1024
    return converted_value.to_i
  end

  def convert_to_GB(value)
    converted_value = (value/1024).round(2)
    return converted_value.to_i
  end

  def convert_to_MHz(value)
    converted_value = value*1000
    return converted_value.to_i
  end

  def convert_to_GHz(value)
    converted_value = (value/1000).round(2)
    return converted_value.to_i
  end

  def empty_boxes_required?(items)
    return true if items.size < 4
    return false
  end

  def empty_boxes_count(items)
    return items.size+1
  end

end
