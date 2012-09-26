desc "send email to user"
  task :send_contents_email,:arg1, :needs => :environment do | t, args|
    follow_users = User.join_follows.where("follows.followable_type in (?) and users.last_sign_in_at<=?",Item::FOLLOWTYPES,1.weeks.ago).select('distinct users.email,users.id')
     #user = User.find(args[:arg1].to_i)
     follow_users.each do |user|
       follow_friends_ids = [user.id] + User.get_follow_users_id(user)
       root_item_ids = []
       follow_item_ids = []
          Item::FOLLOWTYPES.each do |type| 
          it = [] 
          it+= Follow.where('follower_id =? and followable_type in (?)',user.id,type).collect(&:followable_id).uniq
          unless it.blank?
            case type
            when 'Mobile' 
              root_item_ids<<  configatron.root_level_mobile_id.to_s
              follow_item_ids+= it
        
            when 'Camera'
              root_item_ids<< configatron.root_level_camera_id.to_s
              follow_item_ids+= it
         
            when 'Tablet' 
              root_item_ids << configatron.root_level_tablet_id.to_s
              follow_item_ids+= it
        
            when 'Bike'
              root_item_ids<< configatron.root_level_tablet_id.to_s
              follow_item_ids+= it
            when "CarGroup"
              root_item_ids << configatron.root_level_car_id.to_s
              it.each do |i|
               object = Item.find(i)
               follow_item_ids+= object.related_cars.collect(&:id)
             end 
           when "Car"
             root_item_ids << configatron.root_level_car_id.to_s
             follow_item_ids+= it
           when "Manufacturer"
             root_item_ids << configatron.root_level_car_id.to_s  
             it.each do |i|
               object = Item.find(i)
               follow_item_ids+= object.related_cars.collect(&:id)
            end 
           when 'Cycle'
            root_item_ids <<  configatron.root_level_cycle_id.to_s 
             follow_item_ids+= it
           end
          end 
          end
          vote_count = configatron.root_content_vote_count
       @contents = Content.joins("INNER JOIN `item_contents_relations_cache` ON item_contents_relations_cache.content_id = contents.id").where("item_contents_relations_cache.item_id in (?) and contents.created_at >=? and contents.status=? or(contents.created_by in (?) and contents.created_at >=? and contents.status =?) or (item_contents_relations_cache.item_id in (?) and contents.total_votes>=? and contents.created_at >=? and contents.status =?)",follow_item_ids,2.weeks.ago,1, follow_friends_ids,2.weeks.ago,1,root_item_ids,vote_count,2.weeks.ago,1).select("distinct(contents.id), contents.*").order("contents.created_at desc").limit(10)
       if @contents.size > 0
         ContentMailer.my_feeds_content(@contents,user).deliver
       end 
     end
    end
  
