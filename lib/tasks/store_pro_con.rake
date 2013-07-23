desc "save pro cons from article content in item_pro_cons table"
  task :store_pro_con, :needs => :environment do | t, args|
     count = 0
     #item = Item.find(5414)
     items = Item.find_by_sql("select * from items where itemtype_id  in (6,12)")
     items.each do |item|
          item.populate_pro_con
     end
 end

 

