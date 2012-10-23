class AddAvtivityIdToUserActivities < ActiveRecord::Migration
  def change
     add_column :user_activities,:activity_id,:integer
     add_column :user_activities,:ip_address,:string
      UserActivity.delete_all
       Content.all.where(:status =>1).each do |c|
         u = UserActivity.new
         u.user_id = c.created_by
         u.related_id = c.id
         u.related_activity = c.type == "AnswerContent" ? "answered" : "created"
         u.related_activity_type = c.type == "AnswerContent" ? "Q&A" : c.sub_type
         u.activity_id = c.id
         u.time = c.created_at
         u.save 
      end  
      
      Follow.where("followable_type =? and follow_type =?","User","Plannto").each do |f|
        u = UserActivity.new
        u.user_id = f.follower_id
        u.related_id = f.followable_id
        u.related_activity = "followed"
        u.related_activity_type = "User"
        u.activity_id = f.followable_id
        u.time = f.created_at
        u.save 
     end 
     Comment.all.where(:status =>1).each do |f|
        u = UserActivity.new
        u.user_id = f.user_id
        u.related_id = f.commentable_id
        u.related_activity = "commented"
        content = Content.find(f.commentable_id)
        u.related_activity_type =  content.type == "AnswerContent" ? "Answer" : content.sub_type
        u.activity_id = f.id
        u.time = f.created_at
        u.save
    end  
     Vote.all.each do |f|
        unless f.vote.nil?
         u = UserActivity.new
         u.user_id = f.voter_id
         u.related_id = f.voteable_id
         u.related_activity = f.vote? ? "voted" : "downvoted"
         content = Content.find(f.voteable_id)
         u.related_activity_type =  content.type == "AnswerContent" ? "Answer" : content.sub_type
         u.activity_id = f.id
         u.time = f.created_at
         u.save 
    end   
    end 
  end
end
