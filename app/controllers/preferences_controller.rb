class PreferencesController < ApplicationController
  #before_filter :authenticate_user!, :only => [:new]
  #before_filter :authenticate_user!
  layout "product"

  def index
    @question = UserQuestion.find(:first)
  end

  def show
    require 'will_paginate/array'
    @buying_plan = BuyingPlan.find_by_uuid(params[:uuid])
  #@buying_plan = BuyingPlan.where("uuid = ? and buying_plans.deleted != ? ",params[:uuid], true).first
    unless session[:counter]
       session[:counter]=1
     else
       session[:counter]+= 1
     end    
    if current_user
      if @buying_plan.user.id != current_user.id && session[:counter] == 1
        params[:type] = "Recommendations"
      end
    elsif session[:counter] == 1
       params[:type] = "Recommendations"
    end 
    if params[:type] == "create"
      params[:type] = nil
    end    
    @question = @buying_plan.user_question
    @answers = @question.try(:user_answers)
    @preferences = Preference.where("buying_plan_id = ?", @buying_plan.id).includes(:search_attribute)
    @preferences_list = Preference.get_items(@preferences)
    @itemtype = @buying_plan.itemtype
    @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
   @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type) rescue ""
    if @follow_item == ""
       @considered_items = Item.where('id in (?)',(@buying_plan.items_considered.split(",") rescue 0) )
       @item_ids = []
      if @considered_items.size > 0
        @item_ids =  @considered_items.collect(&:id).join(",")
        @where_to_buy_items = Itemdetail.where("itemid in (?) and status = 1 and isError = 0", @item_ids.split(",")).includes(:vendor).order(:price)
      end
   else   
    @item_ids = []
    if @follow_item.size >0
      @item_ids = @follow_item[@itemtype.itemtype].collect(&:followable_id).join(",") 
      @where_to_buy_items = Itemdetail.where("itemid in (?) and status = 1 and isError = 0", @item_ids.split(",")).includes(:vendor).order(:price)
    end
   end 
    if params[:type] == "guides"
      @item_ids = ""
      @guide = Guide.find(1)
    end 
      @article_categories = ArticleCategory.get_by_itemtype(0) 
      sunspot_search_items
    if params[:type] == "Recommendations"
      if @preferences_list.size == 0
        ids = RelatedItem.find_by_sql("select distinct related_item_id from related_items where item_id in (#{@item_ids.blank? ? 0 :@item_ids }) and related_item_id not in (#{@item_ids.blank? ? 0 :@item_ids}) order by variance desc").collect(&:related_item_id)
        @related_items = Item.where('id in (?)',ids).paginate :page => params[:page],:per_page => 10
        @preference = "true"
     else
        search_preference_tems(@buying_plan,@itemtype,params[:page],"1")
      end  
    end
   
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

  def add_preference
    BrowserPreference.add_preference(current_user.id, params[:search_type], params)
    render :nothing => true
  end

  def plan_to_buy
    @page = params[:page]
    @itemtype = Item.find(params[:item_id]).itemtype #by shan
    @per_page = params[:per_page] || 4
    require 'will_paginate/array'
    follow_type = params[:follow_type] = "buyer"  #by shan
    unless follow_type == ""
      follow = follow_item(params[:follow_type],params[:item_id])
      get_follow_items
      @valid = true
      if follow.blank?
        flash[:notice] = "You already buy this Item"
        @valid = true
      else
        flash[:notice] = "Planning is saved"
      end
    else
      @valid = true
      get_follow_items
    end
     current_user.clear_user_follow_item rescue ''
  end
  
  def owned_description_save
    buying_plan = BuyingPlan.find(params[:buying_plan][:plan_id])
    buying_plan.update_attribute('owned_item_description', params[:buying_plan][:owned_item_description])
  end
  
  def owned_item
    Follow.wizard_save(params[:item_id],"owner",current_user)
    current_user.clear_user_follow_item
    type = Item.find(params[:item_id]).type
    item_type_id = Itemtype.find_by_itemtype(type).id
    @plan = BuyingPlan.where(:user_id => current_user.id, :itemtype_id => item_type_id).first
    @follow_types = Itemtype.get_followable_types(@plan.itemtype.itemtype)
    @follow_item = Follow.for_follower(@plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer) #.group_by(&:followable_type)
    item_ids = @follow_item.collect(&:followable_id).join(',')
    @plan.update_attribute('owned_item_id',params[:item_id])
    @plan.update_attributes(:completed => true)
    @plan.update_attribute('items_considered',item_ids)
    UserActivity.save_user_activity(current_user,@plan.id,"completed","Buying Plan",@plan.id,request.remote_ip)
    @follow_item.each do |item|
      item.destroy
    end    
  end
  
  def new
    @itemtype = Itemtype.find_by_itemtype(params[:search_type])
    if params[:without_login] == "true"
      @buying_plan = BuyingPlan.find_or_create_by_temporary_buying_plan_ip_and_user_id_and_itemtype_id_and_completed(:temporary_buying_plan_ip => request.remote_ip,:user_id => 0, :itemtype_id => @itemtype.id,:completed => false)
    else   
      @buying_plan = BuyingPlan.find_or_create_by_user_id_and_itemtype_id_and_completed(:user_id => current_user.id, :itemtype_id => @itemtype.id,:completed => false)
    end 
     @question = @buying_plan.user_question #.destroy
     @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
    logger.info @follow_types
  if params[:without_login] == "true"
    @considered_items = Item.where('id in (?)',(@buying_plan.items_considered.split(",") rescue 0) )
  else  
    @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type)
  end  
logger.info @follow_item  
    if @question.nil?
    @question = UserQuestion.new(:title => "Planning to buy a #{@buying_plan.itemtype.itemtype}", :buying_plan_id => @buying_plan.id)
   @question.save
   end
    @search_type = params[:search_type]
    sunspot_search_items
  end

  def edit_preference
    @buying_plan = BuyingPlan.find(params[:id])
    @question = @buying_plan.user_question

    sunspot_search_items
  end
  
  def create_preference
  require 'will_paginate/array'
    @itemtype = Itemtype.find_by_itemtype(params[:search_type])
     if params[:without_login] == "true"
      @buying_plan = BuyingPlan.find_or_create_by_temporary_buying_plan_ip_and_user_id_and_itemtype_id_and_completed(:temporary_buying_plan_ip => request.remote_ip,:user_id => 0, :itemtype_id => @itemtype.id,:completed => false)
    else   
      @buying_plan = BuyingPlan.find_or_create_by_user_id_and_itemtype_id_and_completed(:user_id => current_user.id, :itemtype_id => @itemtype.id,:completed => false)
      UserActivity.save_user_activity(current_user,@buying_plan.id,"added","Buying Plan",@buying_plan.id,request.remote_ip)
    end 
  
    @buying_plan.update_attribute(:deleted, false)
    @buying_plan.update_attribute(:completed, false)
    Preference.update_preferences(@buying_plan.id, params[:search_type], params)
    require 'will_paginate/array'
   if params[:without_login] == "true"
      @buying_plans = BuyingPlan.where("temporary_buying_plan_ip = ?", request.remote_ip)
   else   
     @buying_plans = BuyingPlan.where("user_id = ?", current_user.id)
   end
    #@preferences = Preference.where("buying_plan_id = ?", @buying_plan.id).includes(:search_attribute)
    #@preferences_list = Preference.get_items(@preferences)

    @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
    logger.info @follow_types
   if params[:without_login] == "true"
      @considered_items  = Item.where('id in (?)',(@buying_plan.items_considered.split(",") rescue 0))
   else   
     @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type)
   end 
logger.info @follow_item   
  end

  def update_preference
    @buying_plan = BuyingPlan.find(params[:id])
    Preference.update_preferences(@buying_plan.id, params[:search_type], params)
    render :nothing => true
  end

  def get_advice
    @itemtype = Itemtype.find_by_itemtype(params[:search_type])
    #search_attributes = SearchAttribute.where("itemtype_id =?", @itemtype.id)
    @buying_plan = BuyingPlan.find_or_create_by_user_id_and_itemtype_id(:user_id => current_user.id, :itemtype_id => @itemtype.id)
    Preference.update_preferences(@buying_plan.id, params[:search_type], params)
    #search_ids = search_attributes.collect{|item| item.id}
    #@preferences = Preference.where("buying_plan_id = ?", @buying_plan.id).includes(:search_attribute)
    #@preferences_list = Preference.get_items(@preferences)
    @question = UserQuestion.new(:title => "Planning to buy a #{@buying_plan.itemtype.itemtype}", :buying_plan_id => @buying_plan.id)
    #@question.title = "Planning to buy a #{@question.buying_plan.itemtype.itemtype}"
    @question.save
    #url = "#{@buying_plan.preference_page_url}"
    #render :nothing => true
  end

  def save_advice_question
    @question = UserQuestion.new(params[:question])
    @question.title = "Planning to buy a #{@question.buying_plan.itemtype.itemtype}"
    @question.save  

    @question.reload
    redirect_to "/preferences/#{@question.buying_plan.itemtype.itemtype.downcase!}/#{@question.buying_plan.uuid}"
  end

  def give_advice
    @question = UserQuestion.find_by_id(params[:question_id])
    @user_answer = UserAnswer.new
  end
  
  def edit_user_question
  @buying_plan = BuyingPlan.find params[:buying_plan_id]
  @question = @buying_plan.user_question
  end

  def update_question
    @question = UserQuestion.find(params[:question_id])
    @question.question = params[:question]
    if params[:title]!="" && !params[:title].nil?
    @question.title = params[:title]
    end 
    @question.plannto_network = params[:plannto_network]
    @question.save
  end
  
  def edit_answer
    @user_answer = UserAnswer.find params[:id]
  end
  
  def update_answer
    @user_answer = UserAnswer.find params[:id]
    @item_ids = params[:recommendation_ids].split(',')
    @user_answer.recommendations.each do |rec|
      rec.destroy
    end
    
    @item_ids.each do |item_id|
      @user_answer.recommendations.build(:item_id => item_id)
    end
    @user_answer.answer = params[:user_answer][:answer]
    @user_answer.save
    @user_answer.reload
  end
  
  def delete_answer
    @user_answer = UserAnswer.find params[:id]
    @user_answer.destroy
    UserActivity.where("related_activity=? and related_activity_type =? and activity_id=?","recommended","Buying Plan",@user_answer.id).first.destroy
  end

  def save_advice
    @user_answer = UserAnswer.new(params[:user_answer])
    @user_answer.user_question_answers.build(params[:user_question_answers])
    @item_ids = params[:recommendations][:item_id].split(',')
    @item_ids.each do |item_id|
      @user_answer.recommendations.build(:item_id => item_id)
    end
    @user_answer.save
    
    @count = UserQuestion.find(:first, :conditions => {:id =>params[:user_question_answers][:user_question_id]}).user_answers.size
     @buying_plan = UserQuestion.find(params[:user_question_answers][:user_question_id]).buying_plan
     UserActivity.save_user_activity(current_user,@buying_plan.id,"recommended","Buying Plan", @user_answer.id,request.remote_ip)
  end

  def delete_buying_plan
    @buying_plan = BuyingPlan.find(params[:id])
    @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
     @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer) #.group_by(&:followable_type)
     item_ids = @follow_item.collect(&:followable_id).join(',')
     @buying_plan.remove_user_activities
    #@buying_plan.destroy
    logger.info item_ids
    if params[:type] == "complete"
     
    else
      @buying_plan.update_attributes(:deleted => true, :items_considered => item_ids)
   
    @follow_item.each do |item|
      item.destroy
    end
        end 
   # render :nothing => true
  end
  
  def considered_item_delete
    @buying_plan = BuyingPlan.find(params[:buying_plan_id])
    items_considered =  @buying_plan.items_considered.split(",")
    items_considered.delete(params[:item_id])
    @buying_plan.update_attribute('items_considered',items_considered.join(","))
    @itemtype = @buying_plan.itemtype
    @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type) rescue ''
    @considered_items = Item.where('id in (?)',(@buying_plan.items_considered.split(",") rescue 0))
  end 
  
  private

  def get_follow_items
    @buying_plan = BuyingPlan.find(params[:buying_plan_id])
    @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
    @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type) rescue ''
    if @follow_item == ''
      @considered_items = Item.where('id in (?)',(@buying_plan.items_considered.split(",") rescue 0))
    end   
  end

  def follow_item(follow_type,item_id)
    #Rails.cache.delete("item_follow_"+current_user.id.to_s)
    @item = Item.find(item_id)
    if !@item.blank?     
     follow =  current_user.follow(@item, follow_type) rescue ''
     if follow == ''
       item_considered = []
       buying_plan = BuyingPlan.find_by_temporary_buying_plan_ip_and_itemtype_id(request.remote_ip,@item.itemtype.id)
       items_considered =  buying_plan.items_considered.split(",") rescue []
       items_considered << @item.id
       buying_plan.update_attribute('items_considered',items_considered.uniq.join(","))
    end  
    else
      false
    end
  end

  def sunspot_search_items
    @search_type = @buying_plan.try(:itemtype).try(:itemtype) || @search_type
    itemtype = Itemtype.find_by_itemtype(@buying_plan.try(:itemtype).try(:itemtype) || @search_type)

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


    ############## PREFERENCES SECTION ######################

    preferences = Array.new
    @preferences_list = preferences = Preference.get_preferences(@buying_plan.id, itemtype.id, @search_attributes.collect{|item| item.id})
    ############ PREFERENCE SECTION ENDS#############
    $search_type = @search_type

    @items = Sunspot.search($search_type.camelize.constantize) do
      keywords "", :fields => :name
      #with(:manufacturer, list)  if !params[:manufacturer].blank? #.any_of(@list)
      #with(:manufacturer, list) if (!params[:manufacturer].present? && !list.empty?)
      # with(:cargroup, cargrouplist)  if !params[cargroup[:field_name].to_sym].blank?
      facet :manufacturer
      #facet :cargroup
      dynamic :features do

      end
      dynamic :features_string do

      end

   
    end

  end

end
