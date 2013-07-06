desc "save pro cons from article content in item_pro_cons table"
  task :store_pro_con, :needs => :environment do | t, args|
     count = 0
     #item = Item.find(5414)
     items = Item.find_by_sql("select * from items where id > 4000 and itemtype_id = 6 limit 541400")
     items.each do |item|
          item.populate_pro_con
     end
 end

 

