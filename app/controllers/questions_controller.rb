class QuestionsController < ApplicationController

  # respond_to :json,:html
  
  def show
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
    @question.user = User.find 1
    
    if @question.save
      @comment = Comment.new
      @answer = Answer.new
      render :show
      # respond_to do |format|
        # format.js
        # format.html render :show
      # end
    end
    
  end
  
end
