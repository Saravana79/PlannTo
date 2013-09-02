desc 'save related items in related items table'
    task :related_items => :environment do
      Item.find_by_sql("select distinct item_id from item_contents_relations_cache INNER JOIN contents ON item_contents_relations_cache.content_id = contents.id where contents.sub_type in ('Comparisons') group by content_id having count(*) < 70").each do |item|
        related_content_ids =  Item.find_by_sql("select distinct content_id from item_contents_relations_cache INNER JOIN contents ON item_contents_relations_cache.content_id = contents.id where item_id = #{item.item_id} and contents.sub_type in ('Comparisons') group by content_id having count(*) < 70").collect(&:content_id)
        related_item_ids = Item.find_by_sql("select item_id from item_contents_relations_cache where content_id in (#{related_content_ids.join(",")}) and item_id != #{item.item_id} group by item_id order by count(*) desc,id desc limit 50").collect(&:item_id)
        puts item.item_id.to_s + " - " + related_item_ids.count.to_s
        related_item_ids.uniq.each do |ri|
         # if RelatedItem.where(:item_id => item.item_id,:related_item_id => ri).empty?
            RelatedItem.create(:item_id => item.item_id,:related_item_id => ri,:variance => 10)
         # end
      end
    end
  end 
