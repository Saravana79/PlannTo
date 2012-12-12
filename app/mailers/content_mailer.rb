class ContentMailer < ActionMailer::Base
  default from: "\"PlannTo Weekly Digest\" <admin@plannto.com>"
  def my_feeds_content(contents,user,followed_item_ids)
    @contents = contents
    @username = user.username
    @userfullname = user.name
    @items = Item.where('id in (?)',followed_item_ids[0..5])
    if(contents.size > 0)
    subject = contents[0].title;
  else
  subject = "PlannTo digest for this week"
  end 
    mail(:to => user.email, :subject => subject)
  end
  
  def not_follow_user_content(contents,user,item_ids)
    @contents = contents
    @username = user.username
    @userfullname = user.name
    @items = Item.where('id in (?)',item_ids)
    if(contents.size > 0)
      subject = contents[0].title;
     else
       subject = "PlannTo digest for this week"
      end 
    mail(:to => user.email, :subject => subject)
  end 
  def user_welcome_mail(user)
    @user = user
    buyer_item_ids =  Follow.where("follower_id=? and follow_type =?",user.id,"buyer").collect(&:followable_id)
    @buyer_items = Item.where('id in (?)',buyer_item_ids)
    follow_item_ids = Follow.where("follower_id=? and follow_type =? and followable_type!=?",user.id,"follower","User").collect(&:followable_id)
    owner_item_ids =  Follow.where("follower_id=? and follow_type =?",user.id,"owner").collect(&:followable_id)
    total_ids =   owner_item_ids + follow_item_ids 
    total_ids.each do |t|
      if Item.find(t).type == "Cycle"
         @cycle = "true"
      elsif Item.find(t).type == "Camera"
         @camera = "true"
      end
    end    
     camera_topic_ids = []
     cylce_topic_ids = []
    if @camera == "true" && @cycle == "true"
      camera_topic_ids = configatron.popular_camera_topics.split(",")[0..1]
      cycle_topic_ids = configatron.popular_cycle_topics.split(",")[0] 
    elsif @cycle == "true"
       cycle_topic_ids = configatron.popular_cycle_topics.split(",")
    elsif @camera == "true"
      camera_topic_ids = configatron.popular_camera_topics.split(",")   
    end          
    topic_ids =  (camera_topic_ids + cycle_topic_ids) - follow_item_ids.collect{|i| i.to_s} 
    @followed_topics = Item.where('id in (?)',topic_ids)
  
    @username = user.username
    @userfullname = user.name
    @owned_items = Item.where('id in (?)',owner_item_ids)
     mail(:to => user.email, :subject => 'Welcome to PlannTo')
  end
 end
