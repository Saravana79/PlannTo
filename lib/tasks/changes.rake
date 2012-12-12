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
      content.update_attribute(:total_votes, args[:votes])
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
  
  desc "activate contents"

  task :activate_contents => :environment do
  contents = Content.all
  contents.each do |content|
  content.update_attribute(:status, 1)
  end
  end

end
