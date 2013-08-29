desc 'save related items in related items table'
    task :related_items => :environment do
      Item.where("type in (?)",["Car", "Mobile", "Tablet", "Bike", "Cycle", "Camera"]).each do |item|
        related_item_ids = Item.find_by_sql("select distinct item_id from item_contents_relations_cache where content_id in (select distinct content_id from item_contents_relations_cache INNER JOIN contents ON item_contents_relations_cache.content_id = contents.id where item_id = #{item.id} and contents.sub_type in ('Comparisons') group by content_id having count(*) < 70) and item_id != #{item.id} order by id desc").collect(&:item_id)
        related_item_ids.uniq.each do |ri|
          if RelatedItem.where(:item_id => item.id,:related_item_id => ri).nil?
            RelatedItem.create(:item_id => item.id,:related_item_id => ri,:variance => 10)
          end
      end
    end
  end 
