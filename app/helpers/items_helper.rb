module ItemsHelper
  def display_specifications(item)
    specifications = Array.new
    attributes_list = Array.new
    attributes_list =  Rails.cache.fetch("attributes_list")
    if attributes_list.nil?
      attributes_list = Attribute.where(:priority => true).to_a
      Rails.cache.write('attributes_list', attributes_list)
    end
    item.attribute_values.each do |att|
      field = ""
      attributes_list.each do |list|
        field = list if list.id == att.attribute_id
      end
      if field != ""
        content = get_displayable_content(att, field)
        specifications << content if content != ""
      end
    end
    specifications.to_sentence
  end

  def get_displayable_content(item, attribute)
    content = ""
    unless (item.value == "" || item.value.nil? || item.value == "0")
      if attribute.attribute_type == Attribute::TEXT
        content = "#{item.value}"
      elsif attribute.attribute_type == Attribute::BOOLEAN
        if item.value == "True"
          content = "Has #{attribute.name}"
        end
      elsif attribute.attribute_type == Attribute::NUMERIC
        if (attribute.unit_of_measure == "GB" && item.value.to_f < 1)
          value = convert_to_MB(item.value.to_f)
          content = "#{attribute.name} - #{value} MB" if value != 0
        elsif (attribute.unit_of_measure == "MB" && item.value.to_f >= 1024)
          value = convert_to_GB(item.value.to_f)
          content = "#{attribute.name} - #{value} GB" if value != 0
        elsif (attribute.unit_of_measure == "GHz" && item.value.to_f < 1)
          value = convert_to_MHz(item.value.to_f)
          content = "#{attribute.name} - #{value} MHz" if value != 0
        elsif (attribute.unit_of_measure == "MHz" && item.value.to_f >= 1000)
          value = convert_to_GHz(item.value.to_f)
          content = "#{attribute.name} - #{value} GHz" if value != 0
        else
          content += "#{attribute.name} - #{item.value}"
          unless (attribute.unit_of_measure == "" || attribute.unit_of_measure.nil?)
            content += "  #{attribute.unit_of_measure}"
          end
        end
      else
        content = "#{attribute.name} - #{item.value}"
        unless (attribute.unit_of_measure == "" || attribute.unit_of_measure.nil?)
          content += "  #{attribute.unit_of_measure}"
        end
      end
    end

    return content
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
  value = false 
    attribute_values = AttributeValue.where("item_id in (?) and attribute_id =? and value != ''", ids, attribute_id)
    #if all values are empty or False then no need of dispalying it.
    attribute_values.each do |att|     
     value = true unless (att.value.blank? || att.value == "False")
    end
    
    return false if value == false
    return true if attribute_values.size > 0
    return false
  end

  def group_display_required?(attribute_ids, item_ids)
    return false if attribute_ids.size == 0
    attribute_values = AttributeValue.where("item_id IN (?) and attribute_id IN (?) and value != ''", item_ids, attribute_ids)
    return true if attribute_values.size > 0
    return false
  end

  def item_group_display_required?(attribute_ids, item)
    return false if attribute_ids.size == 0
    attribute_values = Array.new
    item.attribute_values.each do |att|
      attribute_values << att if attribute_ids.include?(att.attribute_id) && att.value != ""
    end
    # attribute_values = AttributeValue.where("item_id IN (?) and attribute_id IN (?) and value != ''", item_ids, attribute_ids)
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

  def display_item_details(item)
    if item.status ==1 && !item.IsError?
    return true
    else
    return false
    end
  end

  def display_shipping_detail(item)
    unless item.shipping.blank?
      unit = ""
      if item.shippingunit == 1
        unit = "hours"
      elsif item.shippingunit == 2
        unit = "Business days"
      elsif item.shippingunit == 3
        unit = "Months"
      elsif item.shippingunit == 4
        unit = "Years"
      end
      "#{item.shipping} #{unit}"
    else
      "N/A"
    end

  end

  def display_price_detail(item)
    if(!item.cashback.nil? && item.cashback != 0.0)
      item.price == 0.0 ? "N/A" :  number_to_indian_currency(item.price - item.cashback).to_s
    else
    item.price == 0.0 ? "N/A" :  number_to_indian_currency(item.price).to_s
    end

  end

  def display_product_page_tabs(item, tab_type)
    html_list = ""
    html_list = case item.type
    when "Manufacturer"
      then
      str = '<li '
      str = str + "#{'class="tab_active"' if tab_type == "overview"}"
      str = str +'><a href="#overview"><span>Overview</span></a></li>
            <li '
      str = str + "#{'class="tab_active"' if tab_type == "all_models"}"
      str = str + ' id="all_variant"><a href="#all_variants" ><span>All Models</span></a></li>'
      
    when "CarGroup"
      then 
      str = '<li '
      str = str + "#{'class="tab_active"' if tab_type == "overview"}"
      str = str +'><a href="#overview"><span>Overview</span></a></li>
            <li '
      str = str + "#{'class="tab_active"' if tab_type == "all_variants"}"
      str = str + ' id="all_variant"><a href="#all_variants" ><span>All Variants</span></a></li>'
      
    else
    str = '<li '
    str = str + "#{'class="tab_active"' if tab_type == "overview"}"
    str = str +'><a href="#overview"><span>Overview</span></a></li>'
    str = str + "<li "
    str = str + "#{'class="tab_active"' if tab_type == "specification"}"
    str = str + '><a href="#specification"><span>Specification</span></a></li>'
    str = str + "<li "
    str = str + "#{'class="tab_active"' if tab_type == "where_to_buy"}"
    str = str + '><a href="#where_to_buy" ><span>Where to Buy</span></a></li>'
    end
    return html_list.html_safe
  end
  
  def display_required(value, required)
    logger.info value
    logger.info required
    return "display: none;" if value != required
  end

  def number_to_indian_currency(number)
    if number
      string = number.to_s
      number = string.to_s.gsub(/(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?/, "\\1,")
    end
    "Rs #{number}"
  end

end
