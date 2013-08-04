desc "save pro cons from article content in item_pro_cons table"
  task :store_pro_con,:arg1, :needs => :environment do | t, args|
     count = 0
     arg1 = args[:arg1]
     #item = Item.find(5414)
    # items = Item.find_by_sql("select * from items where itemtype_id  in (1)")
     #contents = ArticleContent.find_by_sql("select ac.* from article_contents ac inner join contents c on c.id = ac.id where c.sub_type = 'Reviews' and c.status = 1 and (field2 != '' or field3 != '')" )
     contents = ArticleContent.find(:all,:conditions => ['sub_type ="Reviews" and status = 1 and (field2 != "" or field3 != "") and id > ?',arg1 ])
     contents.each do |content|
          content.populate_pro_con
     end
 end

 

