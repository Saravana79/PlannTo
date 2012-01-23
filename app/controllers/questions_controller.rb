class QuestionsController < ApplicationController

  
  before_filter :authenticate_user!, :only => [:new]

  # respond_to :json,:html
  
  def show
    # logger.error "Library ::" + reputation_tester
    @question = Question.find(params[:id])
    @comment = Comment.new
    @answer = Answer.new
  end
  
  def index
    if params[:sort_option] == '2'
      @questions = Question.all(:order => 'questions.updated_at DESC')
    else
      @questions = Question.sort_by_vote_count
    end
    
     respond_to do |format|
      format.js
      format.html
     end
    
  end
  
  def new
    @question = Question.new
  end
  
  def create
    @question = Question.new params[:question]
    @question.user = current_user
    
    if @question.save
      update_user_reputation(@question.user,User::USER_POINTS[:new_question])
      @comment = Comment.new
      @answer = Answer.new
      render :show
    end
    
  end
  
end
