class AnswerContentsController < ApplicationController
  before_filter :authenticate_user!
  layout :false
	def create
		@answer_content = AnswerContent.new params[:answer_content]
		@answer_content.user = current_user
		@answer_content.save_with_items!("") 
		UserActivity.save_user_activity(current_user,@answer_content.id,"answered","Q&A",@answer_content.id,request.remote_ip) if @answer_content
		 Follow.content_follow(@answer_content.question_content,current_user) if @answer_content
	 if current_user.total_points < 10
     @answer_content.update_attribute('status',Content::SENT_APPROVAL) 
     @display = 'false'
    else
      Point.add_point_system(current_user, @answer_content, Point::PointReason::CONTENT_CREATE)  
    end 
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
    @answer_content.remove_user_activities
  end
end
