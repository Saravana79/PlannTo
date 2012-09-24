desc "send email to user"
  task :send_contents_email,:arg1, :needs => :environment do | t, args|
    #follow_users = User.join_follows.where("follows.followable_type in (?)",Item::FOLLOWTYPES).select('distinct users.email,users.id')
     user = User.find(10)
    #follow_users.each do |user|
      follow_item_ids = Follow.where('follower_id =? and followable_type in (?)',user.id,Item::FOLLOWTYPES).collect(&:followable_id)
        related_items = []
        related_items+= follow_item_ids
        follow_item_ids.each do |it| 
          item = Item.find(it)
        if (item.type == "Manufacturer") || (item.type == "CarGroup")
          related_items+= item.related_cars.collect(&:id)
          related_items.delete(it)
        end
       end 
       @contents = Content.joins("INNER JOIN `item_contents_relations_cache` ON item_contents_relations_cache.content_id = contents.id").where("item_contents_relations_cache.item_id in (?) and contents.created_at >=? and contents.status=?", related_items,2.weeks.ago,1).order("contents.created_at desc").limit(10)
       if @contents.size > 0
         ContentMailer.my_feeds_content(@contents,user).deliver
       end 
     #end
    end
    
   

