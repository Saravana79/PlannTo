class SearchController < ApplicationController
   caches_action :autocomplete_items, :cache_path => proc {|c|  { :tag => params[:term],:type => params[:type] ,:content => params[:content], :search_type => params[:search_type]}}
   caches_action :index, :cache_path => Proc.new { |c| string =  c.params.except(:_).inspect
    {:tag => Digest::MD5.hexdigest(string)}}
  layout "product"

 
  def index
    @static_page1 = "true"
    @search_type = params[:search_type]
    itemtype = Itemtype.find_by_itemtype(params[:search_type])
    #session[:warning] = "true"
    #session[:itemtype] = itemtype.itemtype
    status = Array.new
    status << 1
    status << 2
    status = params[:status].split(',') if params[:status].present?
    @search_attributes = Rails.cache.fetch("search_attributes")
    @search_attributes = nil
    if @search_attributes.nil?
      @search_attributes  = SearchAttribute.where("itemtype_id =?", itemtype.id).includes(:attribute).order("sortorder").all      
      Rails.cache.write('search_attributes',  @search_attributes )
    end
    
     @sort = Array.new
     @search_attributes.each do |s|
      if  s.value_type == "GreaterThan" || s.value_type == "LessThen" 
         @sort << [s.attribute.name, s.attribute.name]
      end
    end   
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
    #save preferences
    if user_signed_in?
      browser_user_id = current_user.id
      browser_ip = ""
    else
      browser_user_id = ""
      browser_ip = request.remote_ip
    end


    BrowserPreference.save_browse_preferences(browser_user_id, params[:search_type], params, browser_ip)

    preferences = Array.new
    if user_signed_in? && !request.xhr?
      @preferences_list = preferences = BrowserPreference.get_items_by_user(current_user.id, itemtype.id, @search_attributes.collect{|item| item.id})
    end
    if !user_signed_in? && !request.xhr?
      @preferences_list = preferences = BrowserPreference.get_items_by_ip(browser_ip, itemtype.id, @search_attributes.collect{|item| item.id})
    end
    ############ PREFERENCE SECTION ENDS#############
    $search_type = @search_type
    @sunspot_search_fields = sunspot_search_fields
    @page = params[:page].nil? ? 1 : params[:page].to_i

    unless params[:manufacturer].present?
      if user_signed_in? && !request.xhr?
        preference = @preferences_list.find {|s| s[:value_type] == "manufacturer" }
        list = preference.nil? ? Array.new : preference[:value].split(',')
      else
        list = Array.new
      end
    else
      @manufacturer = params[:manufacturer].blank? ? "" : params[:manufacturer]
      list = @manufacturer.split(',')
    end

    @sort_by = sort_by_option = params[:sort_by].present? ? params[:sort_by] : "Rating"
    @order_by = order_by_option = params[:order_by].present? ? params[:order_by] : "desc"
    @items = Sunspot.search($search_type.camelize.constantize) do
      data_accessor_for($search_type.camelize.constantize).include = [:attribute_values,:item_rating]
      keywords "", :fields => :name
      with(:manufacturer, list) if !params[:manufacturer].blank? #.any_of(@list)
      with(:manufacturer, list) if (!params[:manufacturer].present? && !list.empty?)
      with(:status, status) if !status.empty?
      # with(:cargroup, cargrouplist) if !params[cargroup[:field_name].parameterize.underscore.to_sym].blank?
      facet :manufacturer
      #facet :cargroup
      dynamic :features do
        preferences.each do |preference|
          if preference[:value_type] == "Between"
            with(preference[:attribute_name].parameterize.underscore.to_sym).greater_than(preference[:min_value]) if !params[preference[:min_attribute]].present?
            with(preference[:attribute_name].parameterize.underscore.to_sym).less_than(preference[:max_value]) if !params[preference[:max_attribute]].present?
          elsif preference[:value_type] == "GreaterThan"
            with(preference[:attribute_name].parameterize.underscore.to_sym).greater_than(preference[:value]) if !params[preference[:attribute]].present?
          elsif preference[:value_type] == "LessThen"
            with(preference[:attribute_name].parameterize.underscore.to_sym).less_than(preference[:value]) if !params[preference[:attribute]].present?
          end
        end
        sunspot_search_fields.each do |search|
          if search[:value_type] == "Between"
            with(search[:attribute_name].parameterize.underscore.to_sym).greater_than(params[search[:first_value]]) if !params[search[:first_value]].blank?
            with(search[:attribute_name].parameterize.underscore.to_sym).less_than(params[search[:second_value]]) if !params[search[:second_value]].blank?
          elsif search[:value_type] == "GreaterThan"
            with(search[:attribute_name].parameterize.underscore.to_sym).greater_than(params[search[:first_value]]) if !params[search[:first_value]].blank?
          elsif search[:value_type] == "LessThen"
            with(search[:attribute_name].parameterize.underscore.to_sym).less_than(params[search[:first_value]]) if !params[search[:first_value]].blank?
          end
          facet(search[:attribute_name].parameterize.underscore.to_sym)
        end
        order_by :Price,order_by_option if sort_by_option == "Price" #, :desc)
        if (sort_by_option != "Price" or sort_by_option != "Launch_date" or sort_by_option !="Rating")
          order_by sort_by_option.parameterize.underscore.to_sym, order_by_option
        end
      end
      dynamic :features_string do
        preferences.each do |preference|
          if preference[:value_type] == "Click"
 with(preference[:attribute_name].parameterize.underscore.to_sym, preference[:value]) if !params[preference[:attribute]].present?
          elsif preference[:value_type] == "ListOf.parameterize.underscore.to_symValues"
            with(preference[:attribute_name].parameterize.underscore.to_sym, preference[:search_value]) if !params[preference[:attribute]].present?
          end
        end
        sunspot_search_fields.each do |search|
          if search[:value_type] == "Click"
            with(search[:attribute_name].parameterize.underscore.to_sym, params[search[:first_value]]) if !params[search[:first_value]].blank?
          elsif search[:value_type] == "ListOfValues" #&& search[:attribute_type] == "Text"
            with(search[:attribute_name].parameterize.underscore.to_sym, search[:selected_list]) if !params[search[:first_value]].blank?
          end
          facet(search[:attribute_name].parameterize.underscore.to_sym)
        end
        
      end

      paginate(:page => params[:page], :per_page => 10)      
      order_by :rating_search_result,order_by_option if sort_by_option == "Rating"
      order_by :launch_date,order_by_option if sort_by_option == "Launch_date"
      order_by :created_at,order_by_option
      # order_by :Price, :desc # descending order , check Documentation link below
        

    end
    #order_by :class , :desc

    # if @items.results.count < 10
    # @display = "none;"
    # else
    # @display = "block;"
    # @page += 1
    # end

  end
  def search_items
    @items = Sunspot.search(Product.search_type(params[:search_type])) do
      keywords params[:q].gsub("-",""), :fields => :name
      with :status,[1,2,3]
      #order_by :class, :desc
      paginate(:page => params[:page], :per_page => 10)
      #facet :types
      order_by :orderbyid , :asc
      #order_by :status, :asc      
      order_by :launch_date, :desc
    end
    if !params[:page]
      product_count = 0
       @items.results.each do |item|
         if item.is_a? Product
           product_count = product_count + 1
         end   
       end
      if product_count == 1
        @items.results.each do |item|
          if item.is_a? Product
            redirect_to item.get_url()
          end
        end
      end
   end        
   end
  
  def autocomplete_items
    if params[:type]
      search_type = Product.follow_search_type(params[:type])
    elsif params[:content] == "true"
        search_type = Product.search_type(params[:search_type])
    else
        if params[:search_type].is_a?(Array)
          search_type = Product.search_type(params[:search_type]) + [Game] + [Laptop]
        else
          search_type = Product.search_type(params[:search_type])
        end
    end 
    @items = Sunspot.search(search_type) do
      keywords params[:term].gsub("-",""), :fields => :name
      with :status,[1,2]
      paginate(:page => 1, :per_page => 10) 
      order_by :orderbyid , :asc
      order_by :launch_date, :desc            
      #order_by :status,:asc
    end

    if params[:from_profile]
      exclude_selected = Follow.for_follower(current_user).where(:followable_type => params[:search_type]).collect(&:followable) rescue []
      @items = @items.results - exclude_selected
    else
      @items = @items.results
    end

    results = @items.collect{|item|
    # if item.type == "CarGroup"
     #   type = "Car"
     # else
     if(item.is_a? (Product))
        type = item.type.humanize
     elsif(item.is_a? (Content))
        type = item.sub_type   
     elsif(item.is_a? (CarGroup))
        type = "Groups"
     elsif(item.is_a? (AttributeTag))
        type = "Groups"
    elsif(item.is_a? (ItemtypeTag))
        type = "Topics"
     else
        type = item.type.humanize
      end 
    
     # end
     if  item.is_a?(Item)
      image_url = item.image_url(:small) rescue ""
      url = item.get_url() rescue ""
      # image_url = item.image_url
      {:id => item.id, :value => item.get_name, :imgsrc =>image_url, :type => type, :url => url }
       
    else
      image_url = item.content_photos.first.photo.url(:thumb) rescue "/images/prodcut_reivew.png"
      url = content_path(item)
      # image_url = item.image_url
      {:content_id => item.id, :value => Content.title_display(item.title)  , :imgsrc =>image_url, :type => type, :url => url } 
       end
    }
  if params[:content] == "true"
    results  << {:id => 0, :value => "View all...", :imgsrc =>"", :type => "", :url => params[:term] } if results.size > 9
  end   
    render :json => results
    
  end

  def search_items_by_relavance
    results, selected_list, list_scores, auto_save = Product.call_search_items_by_relavance(params)
    # results, selected_list, list_scores, auto_save = Product.get_search_items_by_relavance(params)
    results = results.select {|each_hsh| each_hsh unless each_hsh[:value].blank?}
    results = results.uniq
    selected_list = selected_list.uniq
    auto_save = "false" if selected_list.blank?
    auto_save = "false" if params[:ac_sub_type] == "Comparisons" && selected_list.count < 2
    p "auto save => #{auto_save}"
    list_scores = list_scores.fill(0, list_scores.count...selected_list.count)
    results << {:selected_list => selected_list, :list_scores => list_scores, :auto_save => auto_save}

    render :json => results
  end

  def autocomplete_manufacturers
    @items = Sunspot.search(Manufacturer) do
      keywords params[:term].gsub("-",""), :fields => :name
      #paginate(:page => 1, :per_page => 6)
    end

    render :json => @items.results.collect{|item| {:id => item.id, :value => "#{item.name}"}}
  end

  def preference_items
    search_type = Preference.search_type(params[:search_type])
    @items = Sunspot.search(search_type) do
      keywords params[:term].gsub("-",""), :fields => :name
      order_by :class, :desc
      paginate(:page => 1, :per_page => 6)
      order_by :class , :desc
    end

    results = @items.results.collect{|item|
      if item.type == "CarGroup"
        image_url = item.image_url(:small)
        type = "Car"
      else
        image_url =item.image_url(:small)
        type = item.type.humanize
      end
      url = item.get_url()
      # image_url = item.image_url
      {:id => item.id, :value => item.get_name, :imgsrc =>image_url, :type => type, :url => url }
    }
    render :json => results

  end

  def message_users
    #
     @message_users = User.find(:all, :conditions => ['email like ? and id !=?',"%#{params[:term]}%", current_user.id])

       results = @message_users.collect{|item|
      {:id => item.id, :value => "#{item.email}", :imgsrc =>"", :type => "", :url => "" }
    }
    render :json => results
  end

   def autocomplete_source_items
     feed_urls = FeedUrl.find_by_sql("select distinct source from feed_urls")
     sources = feed_urls.map(&:source)

     searched_sources = sources.grep(/^#{params[:term]}/)
     results = searched_sources.map {|x| {:id => x, :value => x, :type => "Source", :imgsrc => ""}}

     render :json => results
   end

end
