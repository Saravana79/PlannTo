class AnswersController < ApplicationController
    def create
    # parent = params[:parent].camelize.constantize.find(params[:parent_id]) unless params[:parent].nil? && params[:parent_id].nil?
    question = Question.find params[:parent_id]
    @answer = Answer.new(params[:answer])
    question.answers.push @answer
    @answer.user = User.find(1)

    if question.save
      respond_to do|format|
        format.js { render :create, :status => 201 }
      end
    end
  end
end
