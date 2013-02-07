class FollowsController < ApplicationController
  before_filter :authenticate_user!
  
  def destroy
    follow = Follow.find(params[:id])
    if  follow.followable_type  == "User"
        follow.remove_activity(current_user)
    end
    follow.destroy
    if params[:type] == "wizard"
       session[:wizard] = follow.follow_type
    end
    if params[:buying_plan_id]
      @buying_plan = BuyingPlan.find(params[:buying_plan_id])
      @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
      @itemtype = @buying_plan.itemtype
      @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type)
      @follow_item_ids = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).collect(&:followable_id)
      @follow_item_1 = Item.where('id in (?)', @follow_item_ids)
      @default_considered_items = search_preference_tems(@buying_plan,@itemtype,1,"1").results[0..3] - @follow_item_1
   else
     redirect_to :back, :notice => "Successfully unfollowed."
   end  
  end
  
  def create
    follow = current_user.follows.where(followable_id: params[:follow][:followable_id]).where(followable_type: params[:follow][:followable_type]).first
    if follow.blank?
      current_user.follows.create(params[:follow])
      current_user.clear_user_follow_item
      if params[:follow][:followable_type]  == "User"
        UserActivity.save_user_activity(current_user, params[:follow][:followable_id],"followed","User",params[:follow][:followable_id],request.remote_ip)
      end 
  
      if params[:follow][:follow_type] == "buyer"
        @item = Item.find(params[:follow][:followable_id])
        @itemtype = Itemtype.find_by_itemtype(@item.itemtype.itemtype)
        @buying_plan = BuyingPlan.where(:user_id => current_user.id, :itemtype_id => @itemtype.id,:completed => false,:deleted => false).first
      if @buying_plan.nil?
        @buying_plan = BuyingPlan.create(:user_id => current_user.id, :itemtype_id => @itemtype.id,:deleted => 0)
        UserActivity.save_user_activity(current_user,@buying_plan.id,"added","Buying Plan",@buying_plan.id,request.remote_ip)
       #@buying_plan.update_attribute(:deleted, false)
       #@buying_plan.update_attribute(:completed, false) 
      end  
      if @question.nil?
       @question = UserQuestion.new(:title => "Planning to buy a #{@buying_plan.itemtype.itemtype}", :buying_plan_id => @buying_plan.id)
       @question.save
    end
   
  end

      if params[:follow][:type] == "wizard"
        session[:wizard] = params[:follow][:follow_type]
      end
   else
      current_user.follows.where(followable_id: params[:follow][:followable_id]).where(followable_type: params[:follow][:followable_type]).first.destroy
      current_user.follows.create(params[:follow])
      current_user.clear_user_follow_item
      if params[:follow][:followable_type]  == "User"
        UserActivity.save_user_activity(current_user, params[:follow][:followable_id],"followed","User",params[:follow][:followable_id],request.remote_ip)
      end 
      if params[:follow][:type] == "wizard"
        session[:wizard] = params[:follow][:follow_type]
      end  
    end
      
    redirect_to :back, :notice => "Successfully following."
  end
    def search_preference_tems(buying_plan,search_type,page,status)
    @search_type = search_type.itemtype
    params["status"] = status
    itemtype = search_type
    status = Array.new
    status  << 1
    status = params["status"].split(',') if params["status"].present?
    params={}
     buying_plan.preferences.each do |p|
       if !p.value_2.blank?
          params['max_1'] = p.value_2
          params['min_1'] = p.value_1
       elsif p.search_attribute.attribute_display_name == "Brand" || p.search_attribute.attribute_display_name == "Manufacturer"
          params[:manufacturer] = p.value_1
       else      
         params["#{p.search_attribute.attribute_id}"] = p.value_1
       end 
     end  
     
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
    #save preferences
    if user_signed_in?
      browser_user_id = current_user.id
      browser_ip = ""
    else
      browser_user_id = ""
      browser_ip = request.remote_ip
    end




    preferences = Array.new
    if user_signed_in? && !request.xhr?
      @preferences_list1 = []
    end
    if !user_signed_in? && !request.xhr?
      @preferences_list1 = preferences = []
    end
    ############ PREFERENCE SECTION ENDS#############
    $search_type = @search_type
    @sunspot_search_fields = sunspot_search_fields
    @page  = params[:page].nil? ? 1 : params[:page].to_i    

    unless params[:manufacturer].present?
      if user_signed_in? && !request.xhr?
        preference = @preferences_list1.find {|s| s[:value_type] == "manufacturer" }
        list =  preference.nil? ? Array.new : preference[:value].split(',')
      else
        list = Array.new
      end
    else
      @manufacturer  = params[:manufacturer].blank? ? "" : params[:manufacturer]
      list  = @manufacturer.split(',')
    end
     
    @sort_by = sort_by_option = params[:sort_by].present? ? params[:sort_by] : "Rating"
    @items = Sunspot.search($search_type.camelize.constantize) do
      keywords "", :fields => :name
      with(:manufacturer, list)  if !params[:manufacturer].blank? #.any_of(@list)
      with(:manufacturer, list) if (!params[:manufacturer].present? && !list.empty?)
      with(:status, status) if !status.empty?
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
        end
        order_by :Price if sort_by_option == "Price" #, :desc)
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

      paginate(:page => page, :per_page => 10)
      order_by :name if sort_by_option == "Name"
      order_by :rating,:desc if sort_by_option == "Rating"

      #   order_by :Price, :desc           # descending order , check Documentation link below
    

    end
    #order_by :class , :desc

    # if @items.results.count < 10
    #   @display = "none;"
    # else
    #   @display = "block;"
    #   @page += 1
    # end
  end
 end
