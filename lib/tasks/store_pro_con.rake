desc "save pro cons from article content in item_pro_cons table"
  task :store_pro_con, :needs => :environment do | t, args|
     count = 0
     Content.includes(:items => [:itemtype => :pro_con_categories]).each do |content|
          if content.class == ArticleContent
               content.items.each do |item|
                    count+=1
                    item_pro = item.item_pro_cons.where(:proorcon => "Pro")
                    item_con = item.item_pro_cons.where(:proorcon => "Con")
                    pro_last_index = !item_pro.blank? ? item_pro.last.index : 0
                    con_last_index = !item_con.blank? ? item_con.last.index : 0
                    pros =content.field2 ? content.field2.split(/,|\.|;/) : []
                    cons = content.field3 ? content.field3.split(/,|\.|;/) : []
                    
                    pros.each do |pro|
                         pro_last_index += 1

                         if item.itemtype.pro_con_categories.blank?
                              ItemProCon.find_or_create_by_item_id_and_article_content_id_and_proorcon_and_text(item.id, content.id, "Pro", pro, pro_con_category_id: nil, text: "pro", index: pro_last_index, proandcon: "Pro")
                         else
                              item.itemtype.pro_con_categories.each do |pcc|
                                   pro_con_category_id = pcc.id
                    list = pcc.list.gsub(",", "|")
                                   ItemProCon.find_or_create_by_item_id_and_article_content_id_and_proorcon_and_text(item.id, content.id, "Pro", pro, pro_con_category_id: (pro.match(/#{list}/) ? pcc.id : nil), text: pro, index: pro_last_index, proandcon: "Pro") 
                              end
                         end
                    end
                    cons.each do |con|
                         con_last_index += 1
                         if item.itemtype.pro_con_categories.blank?
                              ItemProCon.find_or_create_by_item_id_and_article_content_id_and_proorcon_and_text(item.id, content.id, "Con", con, pro_con_category_id: nil, text: con, index: con_last_index, proandcon: "Con")
                         else
                              item.itemtype.pro_con_categories.each do |pcc|
                                   pro_con_category_id = pcc.id
                    list = pcc.list.gsub(",", "|")
                                   ItemProCon.find_or_create_by_item_id_and_article_content_id_and_proorcon_and_text(item.id, content.id, "Con", con, pro_con_category_id: (con.match(/#{list}/) ? pcc.id : nil), text: con, index: con_last_index, proandcon: "Con") 
                              end
                         end
                    end
               end
           end
     end
 end
 

