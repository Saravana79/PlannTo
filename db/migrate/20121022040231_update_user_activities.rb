class UpdateUserActivities < ActiveRecord::Migration
  def up
   Content.all.each do |c|
        u = UserActivity.new
        u.user_id = c.created_by
        u.related_id = c.id
        u.related_activity = c.type == AnswerContent ? "answered" : "created"
        u.related_activity_type = c.type == AnswerContent ? "Q&A" : c.sub_type
        u.time = c.created_at
        u.save 
      end  
      
      Follow.where("followable_type =? and follow_type =?","User","Plannto").each do |f|
        u = UserActivity.new
        u.user_id = f.follower_id
        u.related_id = f.followable_id
        u.related_activity = "followed"
        u.related_activity_type = "User"
        u.time = f.created_at
        u.save 
     end 
     Comment.all.each do |f|
        u = UserActivity.new
        u.user_id = f.user_id
        u.related_id = f.commentable_id
        u.related_activity = "commented"
        content = Content.find(f.commentable_id)
        u.related_activity_type =  content.type == "AnswerContent" ? "Answer" : content.sub_type
        u.time = f.created_at
        u.save
    end  
     Vote.all.each do |f|
        unless f.vote.nil?
         u = UserActivity.new
         u.user_id = f.voter_id
         u.related_id = f.voteable_id
         u.related_activity = f.vote.to_i == 1 ? "voted" : "downvoted"
         content = Content.find(f.voteable_id)
         u.related_activity_type =  content.type == "AnswerContent" ? "Answer" : content.sub_type
         u.time = f.created_at
         u.save 
    end   
    end        
  end

  def down
  end
end
