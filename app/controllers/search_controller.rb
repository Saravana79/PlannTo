class SearchController < ApplicationController
  layout "product"

  def index
    @search_type = params[:search_type]
    itemtype = Itemtype.find_by_itemtype(params[:search_type])

    @search_attributes = SearchAttribute.where("itemtype_id =?", itemtype.id).includes(:attribute)
    unless ($search_info_lookups.nil? || $search_type != params[:search_type])
      @search_info_lookups = $search_info_lookups
    else
      $search_info_lookups = @search_info_lookups = Array.new
      @search_attributes.each do |attr_rel|
        unless attr_rel.try(:attribute).nil?
          if (attr_rel.attribute.attribute_type == "Boolean" || attr_rel.value_type == "Click")
            param_1 = {:div_class_name => "boxClick", :vt => attr_rel.value_type, :adn => attr_rel.attribute_display_name, :min_v => attr_rel.minimum_value, :max_v => attr_rel.maximum_value, :av => attr_rel.actual_value, :ut => attr_rel.attribute.unit_of_measure, :vth => attr_rel.value_type.underscore.humanize}
            $search_info_lookups << {:attribute_name =>attr_rel.attribute.name, :id => attr_rel.attribute.id, :name => attr_rel.attribute_display_name, :param_1 =>param_1, :param_2 =>{:field_id => attr_rel.attribute.id, :value => attr_rel.actual_value, :display_name => attr_rel.attribute_display_name}}
          else
            param_1 = {:div_class_name => "box",:vt => attr_rel.value_type, :adn => attr_rel.attribute_display_name, :min_v => attr_rel.minimum_value, :max_v => attr_rel.maximum_value, :av => attr_rel.actual_value, :ut => attr_rel.attribute.unit_of_measure, :step => attr_rel.step, :range => attr_rel.range, :vth => attr_rel.value_type.underscore.humanize}
            $search_info_lookups << {:attribute_name =>attr_rel.attribute.name, :id => attr_rel.attribute.id, :name => attr_rel.attribute_display_name, :param_1 => param_1, :param_2 =>attr_rel.attribute.id}
          end
        end
      end
      @search_info_lookups = $search_info_lookups
    end
    

    unless ($search_form_lookups.nil? || $search_type != params[:search_type])
      @search_form_lookups = $search_form_lookups
    else
      $search_form_lookups = @search_form_lookups = Array.new
      @search_attributes.each do |attr_rel|
        unless attr_rel.try(:attribute).nil?
          if attr_rel.value_type == "Between"
            min_attribute = "min_" + attr_rel.attribute.id.to_s
            max_attribute = "max_" + attr_rel.attribute.id.to_s
            $search_form_lookups << {:field_name =>min_attribute, :attribute_name => attr_rel.attribute.name, :lower => true, :search_display_id => attr_rel.id}
            $search_form_lookups << {:field_name =>max_attribute, :attribute_name => attr_rel.attribute.name, :lower => false, :search_display_id => attr_rel.id}
          else
            @field = @search_form_lookups.find {|s| s[:field_name] == attr_rel.attribute.id.to_s}
            if @field.nil?
              $search_form_lookups << {:field_name =>attr_rel.attribute.id.to_s, :attribute_name => attr_rel.attribute.name, :search_display_id => attr_rel.id}
            end
          end
        end
      end
      @search_form_lookups = $search_form_lookups
    end

    sunspot_search_fields = Array.new
    @search_attributes.each do |search_attr|
      unless search_attr.try(:attribute).nil?
        if search_attr.value_type == "Between"
          first_value = @search_form_lookups.find {|s| s[:attribute_name] == "#{search_attr.attribute.name}" && s[:lower] == true }
          first_value = first_value[:field_name] unless first_value.nil?
          second_value = @search_form_lookups.find {|s| s[:attribute_name] == "#{search_attr.attribute.name}" && s[:lower] == false }
          second_value = second_value[:field_name] unless second_value.nil?
        elsif search_attr.value_type == "ListOfValues"
          first_value = @search_form_lookups.find {|s| s[:attribute_name] == "#{search_attr.attribute.name}" }
          unless first_value.nil?
            selected_list = params[first_value[:field_name]]
            selected_list_of_values = selected_list.split(",") unless selected_list.nil?
            first_value = first_value[:field_name]
          end
        else
          first_value = @search_form_lookups.find {|s| s[:attribute_name] == "#{search_attr.attribute.name}" }
          first_value = first_value[:field_name] unless first_value.nil?
        end
        field = sunspot_search_fields.find {|s| s[:attribute_name] == search_attr.attribute.name.to_s}
        if field.nil?
          #if params[first_value] != ""
          sunspot_search_fields << {:attribute_name => search_attr.attribute.name, :attribute_id => search_attr.attribute.id, :attribute_type => search_attr.attribute.attribute_type, :value_type => search_attr.value_type, :first_value => first_value, :second_value => second_value, :selected_list => selected_list_of_values}
          #end
        end
      end
    end

    ############## PREFERENCES SECTION ######################
    preferences = Array.new
    if user_signed_in? && !request.xhr?
      search_ids = @search_attributes.collect{|item| item.id}
      @preferences = BrowserPreference.where("user_id = ? and itemtype_id = ? and search_display_attribute_id in (?)", current_user.id, itemtype.id, search_ids).includes(:search_attribute)
      @preferences_list = preferences = BrowserPreference.get_items(@preferences)
    end
    ############ PREFERENCE SECTION ENDS#############

    $search_type = @search_type
    @sunspot_search_fields = sunspot_search_fields
    @page  = params[:page].nil? ? 1 : params[:page].to_i    


    unless params[:manufacturer].present?
      if user_signed_in? && !request.xhr?
        preference = @preferences_list.find {|s| s[:value_type] == "manufacturer" }
        list =  preference.nil? ? Array.new : preference[:value].split(',')
      else
        list = Array.new
      end
    else
      @manufacturer  = params[:manufacturer].blank? ? "" : params[:manufacturer]
      list  = @manufacturer.split(',')
    end

    #logger.info list.kind_of?(Array)

    @items = Sunspot.search($search_type.camelize.constantize) do
      keywords "", :fields => :name
      with(:manufacturer, list)  if !params[:manufacturer].blank? #.any_of(@list)
      with(:manufacturer, list) if (!params[:manufacturer].present? && !list.empty?)
      # with(:cargroup, cargrouplist)  if !params[cargroup[:field_name].to_sym].blank?
      facet :manufacturer
      #facet :cargroup
      dynamic :features do
        preferences.each do |preference|
          if preference[:value_type] == "Between"
            with(preference[:attribute_name].to_sym).greater_than(preference[:min_value]) if !params[preference[:min_attribute]].present?
            with(preference[:attribute_name].to_sym).less_than(preference[:max_value]) if !params[preference[:max_attribute]].present?
          elsif preference[:value_type] == "GreaterThan"
            with(preference[:attribute_name].to_sym).greater_than(preference[:value]) if !params[preference[:attribute]].present?
          elsif preference[:value_type] == "LessThen"
            with(preference[:attribute_name].to_sym).less_than(preference[:value]) if !params[preference[:attribute]].present?
          end
        end
        sunspot_search_fields.each do |search|
          if search[:value_type] == "Between"
            with(search[:attribute_name].to_sym).greater_than(params[search[:first_value]]) if !params[search[:first_value]].blank?
            with(search[:attribute_name].to_sym).less_than(params[search[:second_value]]) if !params[search[:second_value]].blank?
          elsif search[:value_type] == "GreaterThan"
            with(search[:attribute_name].to_sym).greater_than(params[search[:first_value]]) if !params[search[:first_value]].blank?
          elsif search[:value_type] == "LessThen"
            with(search[:attribute_name].to_sym).less_than(params[search[:first_value]]) if !params[search[:first_value]].blank?
          end
          facet(search[:attribute_name].to_sym)
          #order_by(:Price) #, :desc)
        end
      end
      dynamic :features_string do
        preferences.each do |preference|
          if preference[:value_type] == "Click"
            with(preference[:attribute_name].to_sym, preference[:value]) if !params[preference[:attribute]].present?
          elsif preference[:value_type] == "ListOfValues"
            with(preference[:attribute_name].to_sym, preference[:search_value]) if !params[preference[:attribute]].present?
          end
        end
        sunspot_search_fields.each do |search|
          if search[:value_type] == "Click"
            with(search[:attribute_name].to_sym, params[search[:first_value]]) if !params[search[:first_value]].blank?
          elsif search[:value_type] == "ListOfValues" #&& search[:attribute_type] == "Text"
            with(search[:attribute_name].to_sym, search[:selected_list])  if !params[search[:first_value]].blank?
          end
          facet(search[:attribute_name].to_sym)
        end
        
      end

      paginate(:page => params[:page], :per_page => 10)
      order_by :name
      #   order_by :Price, :desc           # descending order , check Documentation link below
    

    end
    #order_by :class , :desc

    if @items.results.count < 10
      @display = "none;"
    else
      @display = "block;"
      @page += 1
    end
  end

  def search_items
    @page  = params[:page].nil? ? 1 : params[:page].to_i

    @items = Sunspot.search(Manufacturer,CarGroup ) do
      keywords params[:q], :fields => :name
      order_by :class, :desc
      paginate(:page => params[:page], :per_page => 10)
      #facet :types
      order_by :class , :desc
    end
    if @items.results.count < 10
      @display = "none;"
    else
      @display = "block;"
      @page += 1
    end

  end


  def autocomplete_items

    @items = Sunspot.search(Manufacturer,CarGroup, Car, Mobile) do
      keywords params[:term], :fields => :name
      order_by :class, :desc
      paginate(:page => 1, :per_page => 6)
      order_by :class , :desc
    end
    
    results = @items.results.collect{|item|
      if item.type == "CarGroup"
        image_url = "http://plannto.com/images/car/" + item.imageurl
        type = "Car"
      else
        image_url = "http://plannto.com/images/mobile/" + item.imageurl
        type = item.type.humanize
      end
      url = "/#{item.type.tableize}/#{item.id}"      
      {:id => item.id, :value => "#{item.name}", :imgsrc =>image_url, :type => type, :url => url }
    }
    render :json => results
    
  end

  def autocomplete_manufacturers
    @items = Sunspot.search(Manufacturer) do
      keywords params[:term], :fields => :name
      #paginate(:page => 1, :per_page => 6)
    end

    render :json => @items.results.collect{|item| {:id => item.id, :value => "#{item.name}"}}
  end
end
