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
    @content = Content.find(params[:id])
    @content.ip_address = request.remote_ip
    @content.update_attributes(params['answer_content'])
    results = Sunspot.more_like_this(@content) do
      fields :title
      minimum_term_frequency 1
    end
    @related_contents = results.results 
  end
  
  def destroy
    @answer_content = AnswerContent.find(params[:id])
    @answer_content.update_attribute(:status, Content::DELETE_STATUS)
    
  end
end
