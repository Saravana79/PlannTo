class AnswerContentsController < ApplicationController

	def create
		@answer_content = AnswerContent.new params[:answer_content]
		@answer_content.user = User.first
		@item = Item.find params['item_id']
		@answer_content.save_with_items!(params['item_id'])
		respond_to do |format|
			format.html
			format.js
		end
	end	

end
