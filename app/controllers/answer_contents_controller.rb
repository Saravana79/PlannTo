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
	  def update
    @answercontent = Content.find(params[:id])
    @answercontent.ip_address = request.remote_ip
    @answercontent.update_attributes(params['answer_content'])
  end
  
  def destroy
    @answer_content = AnswerContent.find(params[:id])
    @answer_content.update_attribute(:status, Content::DELETE_STATUS)
    
  end
end
