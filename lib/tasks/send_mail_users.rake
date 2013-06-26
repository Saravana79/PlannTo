desc "send email to user"

  task :send_contents_email,:arg1, :needs => :environment do | t, args|

    userid = args[:arg1].to_i
    if( userid != 0)
     follow_users = User.find(:all, :conditions=> ["id = ?" ,userid])
    else
     #follow_users = User.join_follows.where("follows.followable_type in (?) and users.last_sign_in_at<=? and users.my_feeds_email=?",Item::FOLLOWTYPES,1.weeks.ago,1).select('distinct users.id, users.*')
     follow_users = User.join_follows.where("follows.followable_type in (?)  and users.my_feeds_email=?",Item::FOLLOWTYPES,1).select('distinct users.id, users.*')
    end 
    puts follow_users
     follow_users.each do |user|
    unless user.id < 65
       follow_friends_ids =  User.get_follow_users_id(user)
       # for now follower id is commented as there is not proper firend mechanism built in our system yet.
       follow_friends_ids = []
       root_item_ids = []
       follow_item_ids = []
       followed_item_ids = []
          Item::FOLLOWTYPES.each do |type| 
          it = [] 
          it+= Follow.where('follower_id =? and followable_type in (?) and follow_type in (?)',user.id,type,["follower","owner"]).collect(&:followable_id).uniq
          unless it.blank?
            case type
            when 'Mobile' 
              root_item_ids<<  configatron.root_level_mobile_id.to_s
              follow_item_ids+= it
              followed_item_ids+= it
            when 'Camera'
              root_item_ids<< configatron.root_level_camera_id.to_s
              follow_item_ids+= it
              followed_item_ids+= it
            when 'Tablet' 
              root_item_ids << configatron.root_level_tablet_id.to_s
              follow_item_ids+= it
              followed_item_ids+= it
            when 'Bike'
              root_item_ids<< configatron.root_level_bike_id.to_s
              follow_item_ids+= it
              followed_item_ids+= it
            when "CarGroup"
              root_item_ids << configatron.root_level_car_id.to_s
              followed_item_ids+= it
              it.each do |i|
               object = Item.find(i)
               follow_item_ids+= object.related_cars.collect(&:id)
             end 
           when "Car"
             root_item_ids << configatron.root_level_car_id.to_s
             follow_item_ids+= it
             followed_item_ids+= it
           when "Topic"
             follow_item_ids+= it
             followed_item_ids+= it
           when "Manufacturer"
             root_item_ids << configatron.root_level_car_id.to_s
             followed_item_ids+= it  
             it.each do |i|
               object = Item.find(i)
               follow_item_ids+= object.related_cars.collect(&:id)
            end 
           when 'Cycle'
            followed_item_ids+= it 
            root_item_ids <<  configatron.root_level_cycle_id.to_s 
             follow_item_ids+= it
           end
          end 
          end
  
            vote_count = configatron.root_content_vote_count
          content_ids =  Content.find_by_sql("select * from (SELECT distinct(contents.id) as idu, contents.* FROM contents 
INNER  JOIN item_contents_relations_cache ON item_contents_relations_cache.content_id = contents.id 
WHERE 
(
(item_contents_relations_cache.item_id in (#{follow_item_ids.blank? ? 0 : follow_item_ids.join(",")})) or 
(item_contents_relations_cache.item_id in (#{root_item_ids.blank? ? 0 :root_item_ids.join(",")}) and total_votes >= #{vote_count}) 
)and 
(contents.status =1 and contents.created_at >= '#{1.weeks.ago}')
union 
SELECT distinct(contents.id) as idu, contents.* FROM contents 
WHERE 
(contents.created_by in (#{follow_friends_ids.blank? ? 0 :follow_friends_ids.join(",")})) and (contents.status =1 and contents.created_at >='#{2.weeks.ago}')
)a  order by a.total_votes desc, created_at desc limit 10").collect(&:id)
#  if content_ids.size < 10
#       content_ids =  Content.find_by_sql("select * from (SELECT distinct(contents.id) as idu, contents.* FROM contents 
#INNER  JOIN item_contents_relations_cache ON item_contents_relations_cache.content_id = contents.id 
#WHERE 
#(
# (item_contents_relations_cache.item_id in (#{follow_item_ids.blank? ? 0 : follow_item_ids.join(",")})) or 
# (item_contents_relations_cache.item_id in (#{root_item_ids.blank? ? 0 :root_item_ids.join(",")}) and total_votes >= #{vote_count}) 
# )and 
# (contents.status =1 and contents.created_at >= '#{2.weeks.ago}')
# union 
# SELECT distinct(contents.id) as idu, contents.* FROM contents 
# WHERE 
# (contents.created_by in (#{follow_friends_ids.blank? ? 0 :follow_friends_ids.join(",")})) and (contents.status =1 and contents.created_at >='#{4.weeks.ago}')
# )a  order by a.total_votes desc, created_at desc limit 10").collect(&:id)
#   end
  
 # if content_ids.size < 10
 #     content_ids = configatron.top_content_ids.split(",")
 #  end  

  if content_ids.size < 10 
    cont_ids = content_ids + configatron.top_content_ids.split(",")
    @contents =  Content.find(:all, :conditions => ['id in (?)',cont_ids[0..9]],:order => "total_votes desc, created_at desc" ) 
    puts cont_ids[0..9].to_s + " content count"    
  else
    @contents = Content.find(:all, :conditions => ['id in (?)',content_ids] ,:order => "total_votes desc, created_at desc")
 end   
puts user.id.to_s + " - User id"
puts content_ids.to_s + " content Id"
puts "*****"
ContentMailer.my_feeds_content(@contents,user,followed_item_ids).deliver
end
end
end 
 task :send_contents_not_follow_email,:arg1, :needs => :environment do | t, args|
    userid = args[:arg1].to_i
    if( userid != 0)
     not_follow_users = User.find(:all, :conditions=> ["id = ?" ,userid])
    else
     follow_user_ids =  Follow.where("followable_type in(?)", Item::FOLLOWTYPES).select("distinct follower_id").collect(&:follower_id)
      not_follow_users = User.where('id not in (?)', follow_user_ids)
    end 
      @contents =  Content.find(:all, :conditions => ['id in (?)',configatron.top_content_ids.split(",")] ,:order => "total_votes desc" ) 
       top_item_ids = configatron.top_all_item_ids.split(",")
       not_follow_users.each do |user|
         ContentMailer.not_follow_user_content(@contents,user,top_item_ids).deliver
       end     
  end
  
  task :send_buying_plans,:arg1, :needs => :environment do | t, args|
    buying_planid = args[:arg1].to_i
    if(buying_planid != 0)
      puts 'inside plan'
       buying_plans= BuyingPlan.find(:all, :conditions=> ["id = ?" ,buying_planid])
    else
       puts 'outside plan'
       buying_plans = BuyingPlan.where('user_id !=? and deleted =? and completed =?',0,0,0)
    end 
    buying_plans.each do |b_plan|
      ContentMailer.buying_plans(b_plan).deliver
    end     
  end
    
   task :welcome_mail,:arg1,:arg2,:arg3, :needs => :environment do | t, args|
      start_date = args[:arg1]
      
      end_date = args[:arg2]
       userid = args[:arg3].to_i
      if( userid != 0)
        users = User.find(:all, :conditions=> ["id = ?" ,userid])
      else
       users = User.where('created_at >=? and created_at <=?',start_date,end_date)
      end 
       users.each do |user|
         ContentMailer.user_welcome_mail(user).deliver
       end  
       end  
    task :ask_content_write_mail,:arg1, :needs => :environment do | t, args|
      userid = args[:arg1].to_i
      if( userid != 0)
         users = User.find(:all, :conditions=> ["id = ?" ,userid])
      else
        users_1 = User.all
        users_2 = []
        Content.where('sub_type =?','Reviews').map{|c| users_2 << User.find(c.created_by) }
        users = users_1 - users_2.uniq
      end 
       users.each do |user|
         ContentMailer.content_write(user).deliver
       end  
      end 
    
