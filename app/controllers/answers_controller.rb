class AnswersController < ApplicationController
    def create
    # parent = params[:parent].camelize.constantize.find(params[:parent_id]) unless params[:parent].nil? && params[:parent_id].nil?
    question = Question.find params[:parent_id]
    @answer = Answer.new(params[:answer])
    @answer.user = current_user
    question.answers.push @answer
  
    if question.save
      update_user_reputation(@answer.user,User::USER_POINTS[:new_answer])
      respond_to do|format|
        format.js { render :create, :status => 201 }
      end
    end
  end
end
