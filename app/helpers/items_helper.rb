module ItemsHelper
  
  def get_item_ids_to_compare_url(items)
     item_ids = items.collect(&:followable_id)
      if items.size < 2
        return "#"
      elsif items.size > 1 && items.size < 4
        return "/items/compare?ids=#{item_ids.join(',')}"
      else
        return "/items/compare?ids=#{item_ids[0..3].join(',')}"
      end
     return "#"
  end
  
  def display_specifications(item)
    specifications = ""
    attributes_list = Array.new
    attributes_list =  Rails.cache.fetch("attributes_list")
    attributes_list = nil
    if attributes_list.nil?
      attributes_list = Attribute.where(:priority => true).to_a
      Rails.cache.write('attributes_list', attributes_list)
    end
    item.attribute_values.joins(:attribute).order("attributes.sortorder").each do |att|
      field = ""
      attributes_list.each do |list|
        field = list if list.id == att.attribute_id
      end
      if field != ""
        content = get_displayable_content(att, field)
        specifications = specifications + content if content != ""
      end
    end
    specificationstemp = "<ul style='list-style-type: disc;font-size: 11px;padding:0px 0px 15px 15px;'>" + specifications + "</ul>"
    specificationstemp.html_safe 
  end

  def get_displayable_content(item, attribute)
    content = ""
    unless (item.value == "" || item.value.nil? || item.value == "0")
      if attribute.attribute_type == Attribute::TEXT        
        unless (attribute.id == 7 && (["bike","tablet","touch","bar","scooter","slr","point & shoot","mirrorless","touchpad"].include?item.value.downcase))          
           content = "#{item.value}"
        end
      elsif attribute.attribute_type == Attribute::BOOLEAN
        if item.value == "True"
          content = "Has #{attribute.name}"
        end
      elsif attribute.attribute_type == Attribute::NUMERIC
        if (attribute.unit_of_measure == "GB" && item.value.to_f < 1)
          value = convert_to_MB(item.value.to_f)
          content = "#{value} MB #{attribute.name}" if value != 0
        elsif (attribute.unit_of_measure == "MB" && item.value.to_f >= 1024)
          value = convert_to_GB(item.value.to_f)
          content = "#{value} GB #{attribute.name} " if value != 0
        elsif (attribute.unit_of_measure == "GHz" && item.value.to_f < 1)
          value = convert_to_MHz(item.value.to_f)
          content = "#{value} MHz #{attribute.name}" if value != 0
        elsif (attribute.unit_of_measure == "MHz" && item.value.to_f >= 1000)
          value = convert_to_GHz(item.value.to_f)
          content = "#{value} GHz #{attribute.name}" if value != 0
        else
          content += "#{item.value}"
          unless (attribute.unit_of_measure == "" || attribute.unit_of_measure.nil?)
            content += "  #{attribute.unit_of_measure}"
          end
          content += " #{attribute.name}"
        end
      else
        if attribute.id == 8
          content = "Launched on #{item.value}"
          

        else
          content = "#{item.value}"
          unless (attribute.unit_of_measure == "" || attribute.unit_of_measure.nil?)
            content += "  #{attribute.unit_of_measure}"
          end

          content += " #{attribute.name}"
        end
      end
    end
    if content.length > 43
      content = content[0..39] + "..."
    end
    if content != ""
      content = "<li style='width:240px;display: list-item;float:left;padding-right:5px;'>" + content + "</li>"
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

  def attribute_display_required?(items, attribute_id)
  value = false 
    attribute_values = items.where("attribute_values.attribute_id =? and (attribute_values.value != '' or attribute_values.value = 'False')", attribute_id)
    # attribute_values = AttributeValue.where("item_id in (?) and attribute_id =? and value != ''", ids, attribute_id)
    #if all values are empty or False then no need of dispalying it.
    # attribute_values.each do |att|     
    #  value = true unless (att.value.blank? || att.value == "False")
    # end
    
    # return false if value == false
    return true if attribute_values.size > 0
    return false
  end

  def group_display_required?(attribute_ids, items)
    return false if attribute_ids.size == 0
    attribute_values = items.where("attribute_values.attribute_id in (?)", attribute_ids)#collect{|i| i.attribute_values}.flatten.collect(&:attribute_id)
    
    # common = attribute_values | attribute_ids
    # logger.info "++++++++++"
     # attribute_values = AttributeValue.where("item_id IN (?) and attribute_id IN (?) and value != ''", items.collect(&:id), attribute_ids)
    return true if attribute_values.size > 0
    return false
  end

  def item_group_display_required?(attribute_ids, item)
    return false if attribute_ids.size == 0
    attribute_values = item.attribute_values.where("attribute_values.attribute_id in (?)", attribute_ids)
    # attribute_values = Array.new
    # item.attribute_values.each do |att|
    #   attribute_values << att if attribute_ids.include?(att.attribute_id) && att.value != ""
    # end
    # attribute_values = AttributeValue.where("item_id IN (?) and attribute_id IN (?) and value != ''", item_ids, attribute_ids)
    return true if attribute_values.size > 0
    return false
  end
  def show_item_value(item, attribute)
    compare_item = item.attribute_values.find_by_attribute_id(attribute.id)#collect.select{|i| i if i.attribute_id == attribute.id}.compact.first #.include(:attribute).select("value, name, unit_of_measure, category_name, attribute_type")
    return "" if compare_item.nil?
    value = display_specification_value(compare_item, attribute)
    return value
  end

  def display_specification_value(item, attribute="")
    attribute = item if attribute == ""
    content = ""
    unless (item.value == "" || item.value.nil?)
      if (!item.valuehyperlink.nil? rescue !item.hyperlink.nil?) && (!item.valuehyperlink.blank?  rescue !item.hyperlink.blank?)
          link = (item.valuehyperlink rescue item.hyperlink)
          if(link).include?("http://") || (link).include?("https://")
          else
             ((item.valuehyperlink = "http://" + link) rescue item.hyperlink = "http://" + link)
          end   
        if attribute.attribute_type == Attribute::TEXT
          if attribute.name == "Product Home Page URL" || attribute.name == "360 Degree View" 
            if(item.value).include?("http://") || (item.value).include?("https://")
            else
              item.value = "http://" + item.value
            end     
            content = "<a href= #{item.value} target='_blank'>#{attribute.name == "Product Home Page URL" ? item.value : "360 Degree View"} </a>"
          else
            content = "<a href= #{item.valuehyperlink rescue item.hyperlink} target='_blank'>#{item.value} </a>"
          end  
      elsif attribute.attribute_type == Attribute::BOOLEAN
        if item.value.downcase == "true"
          content = "<img src='/images/check.png' width='12' height='12'>"
        else
          content = "<img src='/images/close.png' width='12' height='12'>"
        end
      elsif attribute.attribute_type == "Rating"
        stars = render :partial => "products/specification_rating", :locals => {:value => item.value,:item => item}
        content = "<a href= #{item.valuehyperlink rescue item.hyperlink} target='_blank' style='text-decoration: none;'>#{stars}</a>"   
      elsif attribute.attribute_type == Attribute::NUMERIC
        if (attribute.unit_of_measure == "GB" && item.value.to_f < 1)
          value = convert_to_MB(item.value.to_f)
          content = "<a href= #{item.valuehyperlink rescue item.hyperlink} target='_blank'>#{value} MB</a>" if value != 0
        elsif (attribute.unit_of_measure == "MB" && item.value.to_f >= 1024)
          value = convert_to_GB(item.value.to_f)
          content = "<a href= #{item.valuehyperlink rescue item.hyperlink} target='_blank'>#{value} GB</a>" if value != 0
        elsif (attribute.unit_of_measure == "GHz" && item.value.to_f < 1)
          value = convert_to_MHz(item.value.to_f)
          content = "<a href= #{item.valuehyperlink rescue item.hyperlink} target='_blank'>#{value} MHz</a>" if value != 0
        elsif (attribute.unit_of_measure == "MHz" && item.value.to_f >= 1000)
          value = convert_to_GHz(item.value.to_f)
          content = "<a href= #{item.valuehyperlink rescue item.hyperlink} target='_blank'>#{value} GHz</a>" if value != 0
        else
          content += "<a href= #{item.valuehyperlink rescue item.hyperlink} target='_blank'>#{item.value}</a>" 
        unless (attribute.unit_of_measure == "" || attribute.unit_of_measure.nil?)
           content += " #{attribute.unit_of_measure}"
         end
       end
      else
         content += "<a href= #{item.valuehyperlink rescue item.hyperlink} target='_blank'>#{item.value}</a>" 
        unless (attribute.unit_of_measure == "" || attribute.unit_of_measure.nil?)
          content += " #{attribute.unit_of_measure}"
       end
      end
      return content
     else
      if attribute.attribute_type == Attribute::TEXT
        if attribute.name == "Product Home Page URL" || attribute.name == "360 Degree View" 
          if(item.value).include?("http://") || (item.value).include?("https://")
          else
            item.value = "http://" + item.value
          end
          content = "<a href= #{item.value} target='_blank'>#{attribute.name == "Product Home Page URL" ? item.value : "360 Degree View"} </a>"
        else
          content = "#{item.value}"
        end  
     elsif attribute.attribute_type == Attribute::BOOLEAN
       if item.value == "True"
        content = "<img src='/images/check.png' width='12' height='12'>"
       else
         content = "<img src='/images/close.png' width='12' height='12'>"
       end
     elsif   attribute.attribute_type == "Rating"
        content = render :partial => "products/specification_rating", :locals => {:value => item.value,:item => item}
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
     end
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

    when "AttributeTag"
      then 
      str = '<li '
      str = str + "#{'class="tab_active"' if tab_type == "overview"}"
      str = str +'><a href="#overview"><span>Overview</span></a></li>
            <li '
      str = str + "#{'class="tab_active"' if tab_type == "all_variants"}"
      str = str + ' id="all_variant"><a href="#all_variants" ><span>All Variants</span></a></li>'
     
    when "Topic"
     then 
      str = '<li '
      str = str + "#{'class="tab_active"' if tab_type == "overview"}"
      str = str +'><a href="#overview"><span>Overview</span></a></li>
            <li '   
    else
    str = '<li '
    str = str + "#{'class="tab_active"' if tab_type == "overview"}"
    str = str +'><a href="#overview"><span>Overview</span></a></li>'
    str = str + "<li "
    str = str + "#{'class="tab_active"' if tab_type == "specification"}"
    str = str + 'id="specify"><a href="#specification"><span>Specification</span></a></li>'
    str = str + "<li "
    str = str + "#{'class="tab_active"' if tab_type == "where_to_buy"}"
    str = str + 'id="buy"><a href="#where_to_buy" ><span>Where to Buy</span></a></li>'
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
