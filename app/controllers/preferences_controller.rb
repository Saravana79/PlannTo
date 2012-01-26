class PreferencesController < ApplicationController
  layout "product"

  def index
    @question = UserQuestion.find(:first)
  end

  def show
    @buying_plan = BuyingPlan.find_by_uuid(params[:uuid])
    @question = @buying_plan.user_question
    @answers = @question.user_answers
    @preferences = Preference.where("buying_plan_id = ?", @buying_plan.id).includes(:search_attribute)
    @preferences_list = Preference.get_items(@preferences)
  end

  def add_preference
    BrowserPreference.add_preference(current_user.id, params[:search_type], params)
    render :nothing => true
  end

  def get_advice
    @itemtype = Itemtype.find_by_itemtype(params[:search_type])

    search_attributes = SearchAttribute.where("itemtype_id =?", @itemtype.id)
    @buying_plan = BuyingPlan.create(:user_id => current_user.id, :itemtype_id => @itemtype.id)
    Preference.add_preference(@buying_plan.id, params[:search_type], params)    
    search_ids = search_attributes.collect{|item| item.id}
    @preferences = Preference.where("buying_plan_id = ?", @buying_plan.id).includes(:search_attribute)
    @preferences_list = Preference.get_items(@preferences)
  end

  def save_advice_question
    @question = UserQuestion.new(params[:question])
    @question.save
    @question.reload
    redirect_to "/preferences/#{@question.buying_plan.itemtype.itemtype.downcase!}/#{@question.buying_plan.uuid}"
  end

  def give_advice
    @question = UserQuestion.find_by_id(params[:question_id])
    @user_answer = UserAnswer.new
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
  end
end
