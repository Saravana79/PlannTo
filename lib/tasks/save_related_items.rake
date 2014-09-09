desc 'save related items in related items table'
task :related_items => :environment do
  Item.find_by_sql("select distinct item_id from item_contents_relations_cache INNER JOIN contents ON item_contents_relations_cache.content_id = contents.id where contents.updated_at > '#{2.days.ago}' and contents.sub_type in ('Comparisons')").each do |item|
    related_content_ids = Item.find_by_sql("select distinct content_id from item_contents_relations_cache INNER JOIN contents ON item_contents_relations_cache.content_id = contents.id where item_id = #{item.item_id} and contents.sub_type in ('Comparisons')  and contents.status = 1 group by content_id having count(*) < 70").collect(&:content_id)
    unless related_content_ids.empty?
      related_item_ids = Item.find_by_sql("select item_id from item_contents_relations_cache where content_id in (#{related_content_ids.join(",")}) and item_id != #{item.item_id} group by item_id order by count(*) desc,id desc limit 50").collect(&:item_id)
      puts item.item_id.to_s + " - " + related_item_ids.count.to_s
      related_item_ids.uniq.each do |ri|
        # if RelatedItem.where(:item_id => item.item_id,:related_item_id => ri).empty?
        RelatedItem.find_or_create_by_item_id_and_related_item_id(:item_id => item.item_id, :related_item_id => ri, :variance => 10)
        # end
      end
    end
  end
end

desc 'save related items in related items table'
task :related_items_with_count, [:all_item] => :environment do |t, args|
  args.with_defaults(:all_item => "false")
  all_item = args[:all_item]
  time_condition = ""
  if all_item != "true"
    time_condition = "contents.updated_at > '#{1.days.ago.utc}' and"
  end

  query_to_get_items = "select distinct item_id, itemtype_id from item_contents_relations_cache INNER JOIN contents ON item_contents_relations_cache.content_id = contents.id
                    where #{time_condition} contents.sub_type in ('Comparisons')"

  page = 1
  begin
    items = Item.paginate_by_sql(query_to_get_items, :page => page, :per_page => 200)
    items.each do |item|
      query = "select a.item_id as item_id,b.item_id as related_item_id,count(*) as variance from (select content_id, item_id from item_contents_relations_cache ) a join (select content_id,
             item_id from item_contents_relations_cache ) b on  a.content_id = b.content_id where b.item_id != a.item_id and a.item_id = #{item.item_id} and a.content_id in (select id
             from contents where itemtype_id = '#{item.itemtype_id}' and contents.sub_type in ('Comparisons'))  group by item_id,related_item_id order by variance DESC limit 20"

      related_items = RelatedItem.find_by_sql(query)
      related_items.each do |each_rec|
        puts each_rec.item_id.to_s + " - " + each_rec.related_item_id.to_s
        related_item = RelatedItem.find_or_initialize_by_item_id_and_related_item_id(:item_id => each_rec.item_id, :related_item_id => each_rec.related_item_id)
        related_item.update_attributes(:variance => each_rec.variance)
      end
    end
    page += 1
  end while !items.empty?
end