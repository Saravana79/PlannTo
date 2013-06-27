desc "save pro cons from article content in item_pro_cons table"
  task :store_pro_con, :needs => :environment do | t, args|
     ProConCategory.includes(:itemtype => [:contents => [:items => :item_pro_cons]]).each do |pcc|
          pcc.itemtype.contents.each do |content|
               if content.class == ArticleContent
                    content.items.each do |item|
                         last_item = item.item_pro_cons.last
                         last_index = last_item ? last_item.index : 0
                         pros =content.field2 ? content.field2.split(/,|\.|;/) : []
                         cons = content.field3 ? content.field3.split(/,|\.|;/) : []
                         pro_con_categandy_id = pcc.id
                         list = pcc.list.gsub(",", "|")
                         pros.each do |pro|
                              last_index += 1
                              ItemProCon.find_or_create_by_item_id_and_article_content_id_and_pro_con_categandy_id(item.id, content.id, pcc.id, text: "pro", index: 1, proandcon: "Pro") if pro.match(/#{list}/)
                         end
                         cons.each do |con|
                              last_index += 1
                              ItemProCon.find_or_create_by_item_id_and_article_content_id_and_pro_con_categandy_id(item.id, content.id, pcc.id, text: con, index: last_index, proandcon: "Con") if con.match(/#{list}/)
                         end
                    end
                end
          end
     end
 end
 

