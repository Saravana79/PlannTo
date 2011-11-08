class SearchController < ApplicationController

  def index
    itemtype = Itemtype.find_by_itemtype(Car)

    @search_attributes = SearchAttribute.where("itemtype_id =?", itemtype.id)
    #session[:search_display] = {"article_id" => params[:id], "value" => params[:value]}
    @search_info_lookups = Array.new
    @search_attributes.each do |attr_rel|
      unless attr_rel.try(:attribute).nil?
        if attr_rel.attribute.name == "Fuel Type"        
          param_1 = {:vt => attr_rel.value_type, :adn => attr_rel.attribute_display_name, :min_v => attr_rel.minimum_value, :max_v => attr_rel.maximum_value, :av => attr_rel.actual_value, :ut => attr_rel.attribute.unit_of_measure, :vth => attr_rel.value_type.underscore.humanize}
          @search_info_lookups << {:id => attr_rel.attribute.id, :name => attr_rel.attribute_display_name, :param_1 =>param_1, :param_2 =>{:field_id => attr_rel.attribute.id, :value => attr_rel.actual_value, :display_name => attr_rel.attribute_display_name}}
        elsif (attr_rel.attribute.attribute_type == "Boolean" || attr_rel.attribute.name == "Transmission Type")
          
          param_1 = {:vt => attr_rel.value_type, :adn => attr_rel.attribute_display_name, :min_v => attr_rel.minimum_value, :max_v => attr_rel.maximum_value, :av => attr_rel.actual_value, :ut => attr_rel.attribute.unit_of_measure, :vth => attr_rel.value_type.underscore.humanize}
          @search_info_lookups << {:id => attr_rel.attribute.id, :name => attr_rel.attribute_display_name, :param_1 =>param_1, :param_2 =>{:field_id => attr_rel.attribute.id, :value => attr_rel.actual_value, :display_name => attr_rel.attribute_display_name}}
        else
          param_1 = {:vt => attr_rel.value_type, :adn => attr_rel.attribute_display_name, :min_v => attr_rel.minimum_value, :max_v => attr_rel.maximum_value, :av => attr_rel.actual_value, :ut => attr_rel.attribute.unit_of_measure, :vth => attr_rel.value_type.underscore.humanize}
          @search_info_lookups << {:id => attr_rel.attribute.id, :name => attr_rel.attribute_display_name, :param_1 => param_1, :param_2 =>attr_rel.attribute.id}
        end
      end
    end

    @search_form_lookups = Array.new
    @search_attributes.each do |attr_rel|
      unless attr_rel.try(:attribute).nil?
        if attr_rel.value_type == "Between"
          min_attribute = "min_" + attr_rel.attribute.id.to_s
          max_attribute = "max_" + attr_rel.attribute.id.to_s
          @search_form_lookups << {:field_name =>min_attribute, :attribute_name => attr_rel.attribute.name, :lower => true}
          @search_form_lookups << {:field_name =>max_attribute, :attribute_name => attr_rel.attribute.name, :lower => false}
        else
          @field = @search_form_lookups.find {|s| s[:field_name] == attr_rel.attribute.id.to_s}
          if @field.nil?
            @search_form_lookups << {:field_name =>attr_rel.attribute.id.to_s, :attribute_name => attr_rel.attribute.name}
          end
        end
      end
    end
     
    @page  = params[:page].nil? ? 1 : params[:page].to_i
    @manufacturer  = params[:manufacturer].blank? ? "" : params[:manufacturer] 
    min_price = @search_form_lookups.find {|s| s[:attribute_name] == "Price" && s[:lower] == true }
    max_price = @search_form_lookups.find {|s| s[:attribute_name] == "Price" && s[:lower] == false }
    min_onroad_price =@search_form_lookups.find {|s| s[:attribute_name] == "On Road Price" && s[:lower] == true }
    max_onroad_price = @search_form_lookups.find {|s| s[:attribute_name] == "On Road Price" && s[:lower] == true }
    fuel_type = @search_form_lookups.find {|s| s[:attribute_name] == "Fuel Type" }
    min_fuel_eco_city = @search_form_lookups.find {|s| s[:attribute_name] == "Fuel Economy [City]"  }
    #max_fuel_eco_city = @search_form_lookups.find {|s| s[:attribute_name] == "Fuel Economy [City]" && s[:lower] == false }
    min_fuel_eco_highway = @search_form_lookups.find {|s| s[:attribute_name] == "Fuel Economy [Highway/NH]"  }
    #max_fuel_eco_highway = @search_form_lookups.find {|s| s[:attribute_name] == "Fuel Economy [Highway/NH]" && s[:lower] == false }
    min_fuel_eco_avg = @search_form_lookups.find {|s| s[:attribute_name] == "Fuel Economy [Overall]" }
    #max_fuel_eco_avg = @search_form_lookups.find {|s| s[:attribute_name] == "Fuel Economy [Overall]" && s[:lower] == false }
    ground_clearance = @search_form_lookups.find {|s| s[:attribute_name] == "Groud Clearance" }
    maximum_speed = @search_form_lookups.find {|s| s[:attribute_name] == "Maximum Speed" }
    engine_displacement = @search_form_lookups.find {|s| s[:attribute_name] == "Engine Displacement" }
    transmission_type = @search_form_lookups.find {|s| s[:attribute_name] == "Transmission Type" }
    air_conditioner = @search_form_lookups.find {|s| s[:attribute_name] == "Air Conditioner" }
    anti_lock_braking_system = @search_form_lookups.find {|s| s[:attribute_name] == "Anti-Lock Braking System" }
    driver_air_bags = @search_form_lookups.find {|s| s[:attribute_name] == "Driver Air-Bags" }
    lower_turning_radius = @search_form_lookups.find {|s| s[:attribute_name] == "Minimum Turning Radius" }
    cartype = @search_form_lookups.find {|s| s[:attribute_name] == "Type" }
    @cartype  = params[cartype[:field_name].to_sym].blank? ? "" : params[cartype[:field_name].to_sym]

    list  = @manufacturer.split(',')
    cartypelist  = @cartype.split(',')

    @items = Sunspot.search(Car) do
      #keywords "Aston", :fields => :name
      with(:manufacturer, list)  if !params[:manufacturer].blank? #.any_of(@list)
     # with(:cargroup, cargrouplist)  if !params[cargroup[:field_name].to_sym].blank?

      facet :manufacturer
      #facet :cargroup

      dynamic :features do                
        with(:Price).greater_than(params[min_price[:field_name].to_sym]) if !params[min_price[:field_name].to_sym].blank?
        with(:Price).less_than( params[max_price[:field_name].to_sym]) if !params[max_price[:field_name].to_sym].blank?
        with('On Road Price'.to_sym).greater_than(params[min_onroad_price[:field_name].to_sym]) unless min_onroad_price.blank? == true #if !params[min_onroad_price[:field_name].to_sym].blank?
        with('On Road Price'.to_sym).less_than( params[max_onroad_price[:field_name].to_sym]) unless max_onroad_price.blank? == true#if !params[max_onroad_price[:field_name].to_sym].blank?
        with('Fuel Economy [City]'.to_sym).greater_than(params[min_fuel_eco_city[:field_name].to_sym]) unless min_fuel_eco_city.blank? == true#if !params[min_fuel_eco_city[:field_name].to_sym].blank?
        #with('Fuel Economy [City]'.to_sym).less_than( params[max_fuel_eco_city[:field_name].to_sym]) if !params[max_fuel_eco_city[:field_name].to_sym].blank?
        with('Fuel Economy [Highway/NH]'.to_sym).greater_than(params[min_fuel_eco_highway[:field_name].to_sym]) unless min_fuel_eco_highway.blank? == true#if !params[min_fuel_eco_highway[:field_name].to_sym].blank?
        #with('Fuel Economy [Highway/NH]'.to_sym).less_than( params[max_fuel_eco_highway[:field_name].to_sym]) if !params[max_fuel_eco_highway[:field_name].to_sym].blank?
        with('Fuel Economy [Overall]'.to_sym).greater_than(params[min_fuel_eco_avg[:field_name].to_sym]) if !params[min_fuel_eco_avg[:field_name].to_sym].blank? #unless min_fuel_eco_avg.nil? #if !params[min_fuel_eco_avg[:field_name].to_sym].blank?
        #with('Fuel Economy [Overall]'.to_sym).less_than( params[max_fuel_eco_avg[:field_name].to_sym]) if !params[max_fuel_eco_avg[:field_name].to_sym].blank?
        with('Groud Clearance'.to_sym).greater_than(params[ground_clearance[:field_name].to_sym]) if !params[ground_clearance[:field_name].to_sym].blank?
        with('Maximum Speed'.to_sym).greater_than(params[maximum_speed[:field_name].to_sym]) if !params[maximum_speed[:field_name].to_sym].blank?
        with('Engine Displacement'.to_sym).greater_than(params[engine_displacement[:field_name].to_sym]) if !params[engine_displacement[:field_name].to_sym].blank?
        with('Minimum Turning Radius'.to_sym).less_than( params[lower_turning_radius[:field_name].to_sym]) if !params[lower_turning_radius[:field_name].to_sym].blank?
        
        facet(:Engine)
        facet(:Price)
        facet(:'Fuel Economy [City]')        
      end
      dynamic :features_string do
        with('Fuel Type'.to_sym, params[fuel_type[:field_name].to_sym]) if !params[fuel_type[:field_name].to_sym].blank?
        with('Transmission Type'.to_sym, params[transmission_type[:field_name].to_sym]) if !params[transmission_type[:field_name].to_sym].blank?
        with('Air Conditioner'.to_sym, params[air_conditioner[:field_name].to_sym]) if !params[air_conditioner[:field_name].to_sym].blank?
        with('Anti-Lock Braking System'.to_sym, params[anti_lock_braking_system[:field_name].to_sym]) if !params[anti_lock_braking_system[:field_name].to_sym].blank?
        with('Driver Air-Bags'.to_sym, params[driver_air_bags[:field_name].to_sym]) if !params[driver_air_bags[:field_name].to_sym].blank?
        facet ('Fuel Type'.to_sym)
         with('Type'.to_sym, cartypelist)  if !params[cartype[:field_name].to_sym].blank?
         facet ('Type'.to_sym)
      end

      paginate(:page => params[:page], :per_page => 10)
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
    
    @items = Sunspot.search(Manufacturer,CarGroup) do
      keywords params[:term], :fields => :name 
      order_by :class, :desc
      paginate(:page => 1, :per_page => 6)
      order_by :class , :desc
    end
    

    #    @results  = Array.new
    #    @items.results.each do |item|
    #      logger.info(item.attributes)
    #      if item.cargroup.nil?
    #        @results  << {:id => item.id, :value => "#{item.name}", :imgsrc => "/images/B16.jpg", :header => false }
    #      else
    #        @added  =false
    #          @results.each do |result|
    #            if result[:id] == item.cargroup.id
    #               result[:children] << {:id => item.id, :value => "#{item.name}", :imgsrc => "/test/B16.jpg", :header => false }
    #              @added  = true
    #            end
    #          end
    #        @results  << {:id => item.cargroup.id, :value => "#{item.cargroup.name}", :imgsrc => "/images/B16.jpg", :header => true, :children => [{:id => item.id, :value => "#{item.name}", :imgsrc => "/images/B16.jpg", :header => false }]} if @added == false
    #      end
    #    end
    render :json => @items.results.collect{|item| {:id => item.id, :value => "#{item.name}", :imgsrc => "/images/B16.jpg", :type => item.type.humanize }}
  end

  def autocomplete_manufacturers
    @items = Sunspot.search(Manufacturer) do
      keywords params[:term], :fields => :name
      #paginate(:page => 1, :per_page => 6)
    end

    render :json => @items.results.collect{|item| {:id => item.id, :value => "#{item.name}"}}
  end
end
