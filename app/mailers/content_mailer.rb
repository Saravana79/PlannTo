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
  
  def buying_plans(buying_plan)
    @buying_plan = buying_plan
    @user = @buying_plan.user
    @username = @user.username
    @userfullname = @user.name
    @recommendations = @buying_plan.user_question.user_answers.order('created_at desc').limit(10) 
    @itemtype = @buying_plan.itemtype
    @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
    @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type)
    @item_ids = []
    if @follow_item.size >0
      @item_ids = @follow_item[@itemtype.itemtype].collect(&:followable_id).join(",") 
      @where_to_buy_items = Itemdetail.where("itemid in (?) and status = 1 and isError = 0", @item_ids.split(",")).includes(:vendor).order(:price)
    end
    params1 = {"sub_type" => ["Reviews","News","Deals"], "itemtype_id" => @itemtype.id, "status" => 1, "items" => @item_ids.split(","),"order" => 'created_at desc' }
    @contents = Content.filter(params1)
    subject = "#{@buying_plan.user_question.title}" 
    mail(:to => @user.email, :subject => subject)
  end
  
  def user_welcome_mail(user)
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
