class QuestionContentsController < ApplicationController

	def create
		@questioncontent = QuestionContent.new params[:question_content]
		@questioncontent.user = User.first
		#@item = Item.find params['item_id']
		@questioncontent.save_with_items!(params['question_item_id'])
		respond_to do |format|
			format.html
			format.js
		end
	end	

	def show
		@questioncontent = QuestionContent.find params[:id]
		@item = @questioncontent.items[0]
		respond_to do |format|
			format.html
			format.js
		end
	end	

end
