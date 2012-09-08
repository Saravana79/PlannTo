class QuestionContentsController < ApplicationController
  
  before_filter :authenticate_user!
  # => skip_before_filter :verify_authenticity_token
  layout :false

	def create
    @item = Item.find(params[:question_content][:itemtype_id])
		@questioncontent = QuestionContent.new params[:question_content]
    @questioncontent.ip_address = request.remote_ip
		@questioncontent.user = User.first
		#@item = Item.find params['item_id']
		@questioncontent.save_with_items!(params['item_id'])
    
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
    @content = Content.find(params[:id])
    @content.ip_address = request.remote_ip
    @detail = params[:detail]
    @content.update_with_items!(params['question_content'], params[:item_id])
    
     results = Sunspot.more_like_this(@content) do
      fields :title
      minimum_term_frequency 1
    end
    @related_contents = results.results
  end
  
  def destroy
    @content = Content.find(params[:id])
    @content.update_attribute(:status, Content::DELETE_STATUS)
  end

end
