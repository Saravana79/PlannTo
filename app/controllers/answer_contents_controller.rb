class AnswerContentsController < ApplicationController
  before_filter :authenticate_user!
  layout :false
	def create
		@answer_content = AnswerContent.new params[:answer_content]
		@answer_content.user = current_user
		@answer_content.save_with_items!("")   
		respond_to do |format|
			format.html
			format.js
		end
	end	

end
