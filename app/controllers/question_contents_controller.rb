class QuestionContentsController < ApplicationController

	def create
		@questioncontent = QuestionContent.new params[:question_content]
		@questioncontent.user = User.first
		item_id = params['item_id']
		@questioncontent.save_with_items!(item_id)
		respond_to do |format|
			format.html
			format.js
		end
	end	
end
