class BrowserPreference < ActiveRecord::Base
  
  belongs_to :search_attribute, :class_name => "SearchAttribute", :foreign_key => "search_display_attribute_id"

  def self.add_preference(user, search_type, params, ip= "") 
    itemtype = Itemtype.find_by_itemtype(search_type)
    search_attributes = SearchAttribute.by_itemtype(itemtype.id)
    BrowserPreference.clear_items(user, itemtype.id, search_attributes.collect(&:id), ip)
    BrowserPreference.add_items(user, itemtype.id, search_attributes, params, ip)
  end

  def self.get_items(preferences)
    preferences_list = Array.new
    preferences.each do |preference|
      unless preference.search_attribute.nil?
        value_type = preference.search_attribute.value_type
        if value_type == "Between"
          min_value = preference.value_1
          max_value = preference.value_2
          min_attribute = "min_" + "#{preference.search_attribute.attribute_id}"
          max_attribute = "max_" + "#{preference.search_attribute.attribute_id}"
          unit = preference.search_attribute.attribute.unit_of_measure
          search_criteria = " #{preference.search_attribute.value_type.underscore.humanize} #{min_value} #{unit} - #{max_value} #{unit} "
          preferences_list << {:search_name => preference.search_attribute.attribute_display_name, :attribute_name => preference.search_attribute.attribute.name, :value_type => preference.search_attribute.value_type, :min_value => min_value, :min_attribute => min_attribute, :max_value => max_value, :attribute => preference.search_attribute.attribute_id, :max_attribute => max_attribute, :search_criteria => search_criteria}
        elsif value_type == "ListOfValues"
          value = preference.value_1.nil? ? "" : preference.value_1.split(',')
          if preference.search_attribute.attribute_id == 0
            attribute = "manufacturer"
            value_type = "manufacturer"
          else
            attribute = preference.search_attribute.attribute_id
            attribute_name = preference.search_attribute.attribute.name
            value_type = preference.search_attribute.value_type
          end
          preferences_list << {:search_name => preference.search_attribute.attribute_display_name, :attribute_name => attribute_name, :value_type => value_type, :value => preference.value_1, :attribute => attribute, :search_value => value}
        else
          if ((value_type == "GreaterThan") || (value_type == "LessThen"))
            unit = preference.search_attribute.attribute.unit_of_measure
            search_criteria = " #{preference.search_attribute.value_type.underscore.humanize} #{preference.value_1} #{unit} "
          else
            search_criteria = ""
          end
          preferences_list << {:search_name => preference.search_attribute.attribute_display_name, :attribute_name => preference.search_attribute.attribute.name, :value_type => preference.search_attribute.value_type, :value => preference.value_1, :attribute => preference.search_attribute.attribute_id, :search_criteria => search_criteria}
        end
      end
    end
    return preferences_list
  end

  def self.add_items(user, type, search_attributes, params, ip="")
    unless params["manufacturer"].blank?
      manufacturer_id = search_attributes.find {|s| s.attribute_id == 0 }
      BrowserPreference.create(:itemtype_id => type, :user_id => user, :search_display_attribute_id => manufacturer_id.id, :value_1 => params["manufacturer"], :ip => ip)
    end

    search_attributes.each do |search_attr|
      if search_attr.value_type == "Between"
        min_attribute = "min_" + "#{search_attr.attribute_id}"
        max_attribute = "max_" + "#{search_attr.attribute_id}"
        unless params["#{min_attribute}"].blank? && params["#{max_attribute}"].blank?
          min_value = params["#{min_attribute}"]
          max_value = params["#{max_attribute}"]
          BrowserPreference.create(:itemtype_id => type, :user_id => user, :search_display_attribute_id => search_attr.id, :value_1 => min_value, :value_2 => max_value, :ip => ip)
        end
      else
        save = false
        if search_attr.value_type == SearchAttribute::CLICK          
          attribute_field = search_attr.attribute_id  
          save = true if search_attr.actual_value == "#{params["#{attribute_field}"]}"
        else
          attribute_field = search_attr.attribute_id
          save = true
        end
        if save == true
          BrowserPreference.create(:itemtype_id => type, :user_id => user, :search_display_attribute_id => search_attr.id, :value_1 => params["#{attribute_field}"], :ip => ip) unless params["#{attribute_field}"].blank?
        end
      end
    end
  end

  def self.clear_items(user, type, ids, ip="")
    BrowserPreference.delete_all(["user_id = ? and itemtype_id = ? and search_display_attribute_id in (?)", user, type, ids]) unless user == ""
    BrowserPreference.delete_all(["ip = ? and itemtype_id = ? and search_display_attribute_id in (?)", ip, type, ids]) if user == ""
  end

  def self.get_items_by_user(user, itemtype, search_ids)
    preferences = BrowserPreference.where("user_id = ? and itemtype_id = ? and search_display_attribute_id in (?)", user, itemtype, search_ids).includes(:search_attribute)
    BrowserPreference.get_items(preferences)
  end

  def self.get_items_by_ip(ip, itemtype, search_ids)
    preferences = BrowserPreference.where("ip = ? and itemtype_id = ? and search_display_attribute_id in (?)", ip, itemtype, search_ids).includes(:search_attribute)
    BrowserPreference.get_items(preferences)
  end

  def self.save_browse_preferences(user, itemtype, params, ip)
    BrowserPreference.add_preference(user, itemtype, params, ip)
  end
end
