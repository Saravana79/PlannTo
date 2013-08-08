desc "save pro cons from article content in item_pro_cons table"
  task :store_pro_con => :environment do
     count = 0
    # arg1 = args[:arg1]
     #item = Item.find(5414)
    # items = Item.find_by_sql("select * from items where itemtype_id  in (1)")
     #contents = ArticleContent.find_by_sql("select ac.* from article_contents ac inner join contents c on c.id = ac.id where c.sub_type = 'Reviews' and c.status = 1 and (field2 != '' or field3 != '')" )
     sql = "select max(article_content_id) as content_id from item_pro_cons"
     arg1 = ItemProCon.connection.select_value(sql).to_i
     max_average_value = ItemRating.connection.select_value(sql_for_max_average).to_f.round(2).to_s
     contents = ArticleContent.find(:all,:conditions => ['sub_type ="Reviews" and status = 1 and (field2 != "" or field3 != "") and id > ?',arg1 ])
     contents.each do |content|
          content.populate_pro_con
     end
 end

 

