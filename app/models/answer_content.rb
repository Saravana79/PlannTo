class AnswerContent < Content
	acts_as_citier
	belongs_to :question_content
	
	def remove_user_activities
	   UserActivity.where("related_activity =? and related_id =? and activity_id","answered",self.id,self.id).first.destroy
	   UserActivity.where("related_activity_type =? and realted_id=?","Answer",self.id).each do |act|
	     act.destroy
	   end  
	end
end
