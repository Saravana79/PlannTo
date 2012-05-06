class QuestionContentsController < ApplicationController
  
  before_filter :authenticate_user!
  layout :false

	def create
    @item = Item.find(params[:question_content][:itemtype_id])
		@questioncontent = QuestionContent.new params[:question_content]
		@questioncontent.user = User.first
		#@item = Item.find params['item_id']
		@questioncontent.save_with_items!(params['question_item_id'])
    
  end

	def show
		@questioncontent = QuestionContent.find params[:id]
		@item = @questioncontent.items[0]
		respond_to do |format|
			format.html
			format.js
		end
	end

  def update
    @questioncontent = Content.find(params[:id])
    @questioncontent.update_with_items!(params['question_content'], params[:item_id])
  end

end
