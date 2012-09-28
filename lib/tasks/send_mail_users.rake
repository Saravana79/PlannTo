desc "send email to user"
  task :send_contents_email,:arg1, :needs => :environment do | t, args|

    userid = args[:arg1].to_i
    if( userid != 0)
     follow_users = User.find(:all, :conditions=> ["id = ?" ,userid])
    else
     follow_users = User.join_follows.where("follows.followable_type in (?) and users.last_sign_in_at<=? and users.my_feeds_email=?",Item::FOLLOWTYPES,1.weeks.ago,1).select('distinct users.email,users.id,users.username')
    end 

     follow_users.each do |user|
       follow_friends_ids =  User.get_follow_users_id(user)
       root_item_ids = []
       follow_item_ids = []
       followed_item_ids = []
          Item::FOLLOWTYPES.each do |type| 
          it = [] 
          it+= Follow.where('follower_id =? and followable_type in (?)',user.id,type).collect(&:followable_id).uniq
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
              root_item_ids<< configatron.root_level_tablet_id.to_s
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
(item_contents_relations_cache.item_id in (#{follow_item_ids.join(",")})) or 
(item_contents_relations_cache.item_id in (#{root_item_ids.join(",")}) and total_votes >= #{vote_count}) 
)and 
(contents.status =1 and contents.created_at >= '#{1.weeks.ago}')
union 
SELECT distinct(contents.id) as idu, contents.* FROM contents 
WHERE 
(contents.created_by in (#{follow_friends_ids.join(",")})) and (contents.status =1 and contents.created_at >='#{1.weeks.ago}')
)a  order by a.total_votes desc limit 10").collect(&:id) 
  content_ids = content_ids.blank? ? "" : content_ids 
  @contents = Content.find(:all, :conditions => ['id in (?)',content_ids] ,:order => "total_votes desc")
       if @contents.size > 0
         ContentMailer.my_feeds_content(@contents,user,followed_item_ids).deliver
       end 
     end
    end
  
  
  
 
  
