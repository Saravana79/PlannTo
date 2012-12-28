class PreferencesController < ApplicationController
  #before_filter :authenticate_user!, :only => [:new]
  layout "product"

  def index
    @question = UserQuestion.find(:first)
  end

  def show
    require 'will_paginate/array'
    @buying_plan = BuyingPlan.find_by_uuid(params[:uuid])
  #@buying_plan = BuyingPlan.where("uuid = ? and buying_plans.deleted != ? ",params[:uuid], true).first
    @question = @buying_plan.user_question
    @answers = @question.try(:user_answers)
    @preferences = Preference.where("buying_plan_id = ?", @buying_plan.id).includes(:search_attribute)
    @preferences_list = Preference.get_items(@preferences)
    @itemtype = @buying_plan.itemtype
     @guide = Guide.find_by_name("Buyer")
    @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
    logger.info @follow_types
    @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type)
    if @follow_item.size >0
    @item_ids = @follow_item[@itemtype.itemtype].collect(&:followable_id) 
    @where_to_buy_items = Itemdetail.where("itemid in (?) and status = 1 and isError = 0", @item_ids).includes(:vendor).order(:price)
    end
    sunspot_search_items
    @article_categories = ArticleCategory.get_by_itemtype(0)
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
    follow_type = params["follow_type"] = "buyer"  #by shan
    unless follow_type == ""
      follow = follow_item(params[:follow_type])
      if follow.blank?
        flash[:notice] = "You already buy this Item"
        @valid = false
      else
        @valid = true
        flash[:notice] = "Planning is saved"
        get_follow_items
      end
    else
      @valid = true
      get_follow_items
    end
  end
  
  def owned_description_save
    buying_plan = BuyingPlan.find(params[:buying_plan][:plan_id])
    buying_plan.update_attribute('owned_item_description', params[:buying_plan][:owned_item_description])
  end
  
  def owned_item
    Follow.wizard_save(params[:item_id],"owner",current_user)
    type = Item.find(params[:item_id]).type
    item_type_id = Itemtype.find_by_itemtype(type).id
    @plan = BuyingPlan.where(:user_id => current_user.id, :itemtype_id => item_type_id).first
    @follow_types = Itemtype.get_followable_types(@plan.itemtype.itemtype)
    @follow_item = Follow.for_follower(@plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer) #.group_by(&:followable_type)
    item_ids = @follow_item.collect(&:followable_id).join(',')
    @plan.update_attribute('owned_item_id',params[:item_id])
    @plan.update_attributes(:completed => true)
    @plan.update_attribute('items_considered',item_ids)
    UserActivity.save_user_activity(current_user,@buying_plan.id,"completed","Buying Plan",@buying_plan.id,request.remote_ip)
    @follow_item.each do |item|
      item.destroy
    end    
  end
  
  def new
    @itemtype = Itemtype.find_by_itemtype(params[:search_type])
     @buying_plan = BuyingPlan.find_or_create_by_user_id_and_itemtype_id(:user_id => current_user.id, :itemtype_id => @itemtype.id)
      @question = @buying_plan.user_question #.destroy
       @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
    logger.info @follow_types
    @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type)
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
    @buying_plan = BuyingPlan.find_or_create_by_user_id_and_itemtype_id(:user_id => current_user.id, :itemtype_id => @itemtype.id)
    UserActivity.save_user_activity(current_user,@buying_plan.id,"added","Buying Plan",@buying_plan.id,request.remote_ip)
    @buying_plan.update_attribute(:deleted, false)
    @buying_plan.update_attribute(:completed, false)
    Preference.update_preferences(@buying_plan.id, params[:search_type], params)
    require 'will_paginate/array'
    @buying_plans = BuyingPlan.where("user_id = ?", current_user.id)

    #@preferences = Preference.where("buying_plan_id = ?", @buying_plan.id).includes(:search_attribute)
    #@preferences_list = Preference.get_items(@preferences)

    @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
    logger.info @follow_types
    @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type)
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
     buying_plan = UserQuestion.find(params[:user_question_answers][:user_question_id]).buying_plan
     UserActivity.save_user_activity(current_user,buying_plan.id,"recommended","Buying Plan", @user_answer.id,request.remote_ip)
  end

  def delete_buying_plan
    @buying_plan = BuyingPlan.find(params[:id])
    @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
     @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer) #.group_by(&:followable_type)
    item_ids = @follow_item.collect(&:followable_id).join(',')
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
 
  private

  def get_follow_items
    @buying_plan = BuyingPlan.find(params[:buying_plan_id])
    @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
    @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type)
  end

  def follow_item(follow_type)
    #Rails.cache.delete("item_follow_"+current_user.id.to_s)
    @item = Item.find(params[:item_id])
    if !@item.blank?     
      current_user.follow(@item, follow_type)
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
