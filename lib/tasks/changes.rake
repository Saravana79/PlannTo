namespace :plannto do

  desc 'update guides for contents in contents table'
  task :update_guides_to_contents => :environment do
  contents = Content.all
  contents.each do |content|
  guide_ids = content.guides.collect(&:id).join(',')
    content.update_attribute(:content_guide_info_ids, "#{guide_ids}")
    end
  end

  desc 'set created by for contents'
  #sample task  rake plannto:update_votes_for_contents[10,13,'Reviews', 5]
task :update_votes_for_contents, :start_id, :end_id, :sub_type, :votes, :needs => :environment do |t, args|
  
  contents = Content.where("id BETWEEN ? AND ?", args[:start_id], args[:end_id])
  user_ids = configatron.content_creator_user_ids.split(",")
  contents.each do |content|
  puts args[:sub_type]
  puts content.sub_type
    if content.sub_type == args[:sub_type]
    #if content.votes.size == 0
    user_ids.each do |user_id|
    voter = User.find(user_id)      
      unless voter.voted_on? content       
        voter.vote content,:direction => "up"
      end
      end
      content.update_attribute(:total_votes, :total_votes + args[:votes])
     # end
      end
  end
end
  #sample task  rake plannto:update_created_by_for_contents[10,13]
  desc 'set created by for contents'
task :update_created_by_for_contents, :start_id, :end_id, :needs => :environment do |t, args|
  
  contents = Content.where("id BETWEEN ? AND ?", args[:start_id], args[:end_id])
  user_ids = configatron.content_creator_user_ids.split(",")
  contents.each do |content|
  user_id = user_ids.shuffle.first
    content.update_attribute(:created_by, user_id)
    user = User.find user_id
    point = Point.find_by_object_id(content.id)  
    if point.nil?
     points = Point.get_points(content, Point::PointReason::CONTENT_SHARE)
      Point.create(:user_id => user.id, :object_type => GlobalUtilities.get_class_name(content.class.name), :object_id => content.id, :reason => Point::PointReason::CONTENT_SHARE, :points => points)
    else
       point.update_attribute(:user_id, user.id)
    end    
     
     #Point.add_point_system(user, content, Point::PointReason::CONTENT_SHARE) 
  
  end
end


  desc "load article categories"

  task :load_article_categories => :environment do
    ArticleCategory.delete_all

    itemtype = Itemtype.where(:itemtype => "Car").first

    ArticleCategory.create(:name => "Reviews", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Q&A", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Tips", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Accessories", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Travelogue", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Video", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Photo", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "News", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Deals", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Event", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "HowTo/Guide", :itemtype_id => itemtype.id)

    itemtype = Itemtype.where(:itemtype => "Mobile").first

    ArticleCategory.create(:name => "Reviews", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Q&A", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Tips", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Accessories", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Apps", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Video", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Photo", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "News", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Deals", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Event", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "HowTo/Guide", :itemtype_id => itemtype.id)

    itemtype = Itemtype.where(:itemtype => "Camera").first

    ArticleCategory.create(:name => "Reviews", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Q&A", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Tips", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Accessories", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Books", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Video", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Photo", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "News", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Deals", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Event", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "HowTo/Guide", :itemtype_id => itemtype.id)

    itemtype = Itemtype.where(:itemtype => "Tablet").first
    ArticleCategory.create(:name => "Reviews", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Q&A", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Tips", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Accessories", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Apps", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Video", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Photo", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "News", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Deals", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Event", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "HowTo/Guide", :itemtype_id => itemtype.id)

  end

  desc "load bookmark article categories"

  task :load_bookmark_article_categories => :environment do
    ArticleCategory.create(:name => "Reviews", :itemtype_id => 0)
    ArticleCategory.create(:name => "Q&A", :itemtype_id => 0)
    ArticleCategory.create(:name => "Tips", :itemtype_id => 0)
    ArticleCategory.create(:name => "Accessories", :itemtype_id => 0)
    ArticleCategory.create(:name => "Apps", :itemtype_id => 0)
    ArticleCategory.create(:name => "Video", :itemtype_id => 0)
    ArticleCategory.create(:name => "Photo", :itemtype_id => 0)
    ArticleCategory.create(:name => "News", :itemtype_id => 0)
    ArticleCategory.create(:name => "Deals", :itemtype_id => 0)
    ArticleCategory.create(:name => "Event", :itemtype_id => 0)
    ArticleCategory.create(:name => "HowTo/Guide", :itemtype_id => 0)
    ArticleCategory.create(:name => "Travelogue", :itemtype_id => 0)
    ArticleCategory.create(:name => "Apps", :itemtype_id => 0)
    ArticleCategory.create(:name => "Books", :itemtype_id => 0)
  end

  desc "load content itemtype relations"

  task :load_content_itemtype_relations => :environment do
  ContentItemtypeRelation.destroy_all
    contents = Content.all
    contents.each do |content|
      item_ids = ContentItemRelation.where(:content_id => content.id).collect(&:item_id)
      itemtype_ids = Array.new
      item_ids.each do |item_id|
        item = Item.find(item_id)
        itemtype_ids << content.get_itemtype(item)
      end
      itemtype_ids.uniq.each do |itemtype_id|
        ContentItemtypeRelation.create(:itemtype_id => itemtype_id, :content_id => content.id)
      end
    end

  end

  task :update_ratings => :environment do                       
    ItemRating.delete_all
    Item.all.each do |item|  
        created_reviews = Array.new
        complete_created_reviews = item.contents.where("type = 'ReviewContent' and  status = 1")    
        complete_created_reviews.each do |rev|
           created_reviews << rev unless (rev.rating.to_i == 0 || rev.rating.nil?)
        end
        shared_reviews = Array.new
        complete_shared_reviews = item.contents.where("sub_type = 'Reviews' and type != 'ReviewContent' and status = 1" )   
        complete_shared_reviews.each do |rev|   
          shared_reviews << rev unless (rev.field1.to_i == 0 || rev.field1.nil?)
        end
        #return 0 if (created_reviews.empty? && shared_reviews.empty?)
        unless created_reviews.empty?
        created_avg_sum = created_reviews.inject(0){|sum,review| sum += review.rating.to_f} 
        else
            created_avg_sum = 0
        end
        unless shared_reviews.empty?
        shared_avg_sum = shared_reviews.inject(0){|sum,review| sum += review.field1.to_f}
        else
          shared_avg_sum = 0
        end
        if(created_avg_sum == 0 && shared_avg_sum == 0)
        
          item_rating =  0
        
        else
          rating = (created_avg_sum + shared_avg_sum)/(created_reviews.size.to_f + shared_reviews.size.to_f) rescue 0.0
         
        end  
        if (created_avg_sum == 0) || created_reviews.size == 0
           user_review_avg_rating = 0 
        else
            user_review_avg_rating = (created_avg_sum)/(created_reviews.size).to_f rescue 0.0
        end      
         
        if  shared_avg_sum == 0 || shared_reviews.size == 0  
            expert_review_avg_rating = 0
        else
           expert_review_avg_rating = (shared_avg_sum)/(shared_reviews.size).to_f rescue 0.0
        end    
      
         user_review_count = created_reviews.size
         expert_review_count = shared_reviews.size
         expert_review_total_count = complete_shared_reviews.size        
         user_review_total_count = complete_created_reviews.size
       
         average_rating = rating
         review_count =  user_review_count + expert_review_count
         review_total_count =   user_review_total_count   +      expert_review_total_count
        
           item_rating1 = ItemRating.new
           item_rating1.user_review_count = user_review_count
           item_rating1.expert_review_count = expert_review_count
           item_rating1.expert_review_total_count = expert_review_total_count      
           item_rating1.user_review_total_count = complete_created_reviews.size
           item_rating1.expert_review_avg_rating =  expert_review_avg_rating
           item_rating1.user_review_avg_rating = user_review_avg_rating
           item_rating1.average_rating = average_rating 
           item_rating1.review_count =  user_review_count + expert_review_count
           item_rating1.review_total_count =     review_total_count
           item_rating1.item_id = item.id
           item_rating1.save
      end
      
  end

  task :update_rank => :environment do

    date_modifier = configatron.launch_date_modifier.to_s

    Itemtype.where("itemtype in ('Car')").each do |itemtype|  
    
      item_type_id = itemtype.id.to_s
      total_rating_to_consider = configatron.retrieve(("rating_m_for_" + itemtype.itemtype.downcase).to_sym).to_s
      
      avearge_rating_of_average  =  ItemRating.find_by_sql("select avg(average_rating) as avg1 from item_ratings where item_id in (select id from items where itemtype_id = #{item_type_id}) and (average_rating is not null  or average_rating!=0)").first.avg1.to_s
         
      sql_for_max_average = "select calculated_rating - ((case when (launchdatemonth > 0 and launchdatemonth1 != '') then launchdatemonth else createddatedifference end) * "+ date_modifier + ") as final_rating from (select items.name,average_rating,review_count,
            (((review_count/(review_count + " + total_rating_to_consider + ")) * average_rating) + ((" + total_rating_to_consider + "/(review_count+" + total_rating_to_consider + "))*" + avearge_rating_of_average + ")) as calculated_rating ,
            (select value from attribute_values av where av.attribute_id = 8 and av.item_id = item_ratings.item_id) as launchdatemonth1,
            (select period_diff(date_format(now(), '%Y%m'), date_format(str_to_date(value,'%d-%M-%Y') , '%Y%m'))from attribute_values av where av.attribute_id = 8 and av.item_id = item_ratings.item_id) as launchdatemonth,
            period_diff(date_format(now(), '%Y%m'),date_format(items.created_at,'%Y%m')) as createddatedifference
            from item_ratings 
            inner join items on items.id = item_ratings.item_id where itemtype_id = " + item_type_id + " and average_rating != 0 
            ) as a
            order by final_rating desc limit 1"
      
      max_average_value = ItemRating.connection.select_value(sql_for_max_average).to_f.round(2).to_s
      sql_for_rank = "select item_ratings_id, name, calculated_rating - ((case when (launchdatemonth > 0 and launchdatemonth1 != '') then launchdatemonth else createddatedifference end) * "+ date_modifier + ") as final_rating ,
            ((calculated_rating - ((case when (launchdatemonth > 0 and launchdatemonth1 != '') then launchdatemonth else createddatedifference end) * "+ date_modifier + "))/"+ max_average_value +") * 100 as rank from (select item_ratings.id as item_ratings_id,items.name,average_rating,review_count,
            (((review_count/(review_count + " + total_rating_to_consider + ")) * average_rating) + ((" + total_rating_to_consider + "/(review_count+" + total_rating_to_consider + "))*" + avearge_rating_of_average + ")) as calculated_rating ,
            (select value from attribute_values av where av.attribute_id = 8 and av.item_id = item_ratings.item_id) as launchdatemonth1,
            (select period_diff(date_format(now(), '%Y%m'), date_format(str_to_date(value,'%d-%M-%Y') , '%Y%m'))from attribute_values av where av.attribute_id = 8 and av.item_id = item_ratings.item_id) as launchdatemonth,
            period_diff(date_format(now(), '%Y%m'),date_format(items.created_at,'%Y%m')) as createddatedifference
            from item_ratings 
            inner join items on items.id = item_ratings.item_id where itemtype_id = " + item_type_id + " and average_rating != 0 
            ) as a
            order by final_rating desc"

     temp_item_ratings = ItemRating.connection.select_all(sql_for_rank)
     temp_item_ratings.each do |temp_item_rating|
        temp_item_rating_id = temp_item_rating["item_ratings_id"]
        final_rating = temp_item_rating["final_rating"]
        rank = temp_item_rating["rank"]
        if(!rank.nil?)
          rank = rank.round
          if(rank > 100)
            rank = 100
          elsif (rank < 0)
            rank = 0
          end
        end
          
        item_rating = ItemRating.find(temp_item_rating_id)
        item_rating.final_rating = final_rating
        item_rating.rank = rank
        item_rating.save
     end

    end 


  end

  desc "activate contents"

  task :activate_contents => :environment do
  contents = Content.all
  contents.each do |content|
  content.update_attribute(:status, 1)
  end
  end

end
