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

end
