namespace :plannto do
  require 'global_utilities'
  include GlobalUtilities
  desc "task to find the related items"
   
  task :find_related_items => :environment do
    RelatedItem.delete_all
    puts "----TRUNCATED related_items--------"

    # include GlobalUtilities
    item_types = Itemtype.where("itemtype IN ('Car', 'Mobile', 'Camera', 'Tablet','Cycle','Bike')").collect(&:id).join(',')
    #puts item_types
    all_items = Item.where("itemtype_id IN (#{item_types})")
    #puts all_items.size
    all_items.each do |item|
      #puts item.id
      item = Item.find(item.id)
      variance = 20
      search_hash = get_item_priority_list(item, variance)
      numeric_hash = search_hash[:numeric_hash]
      boolean_hash = search_hash[:boolean_hash]
      text_hash = search_hash[:text_hash]
      item_type = item.itemtype.itemtype
      items = get_sunspot_related_items(item_type, numeric_hash, boolean_hash, text_hash)
      #puts item.name
      # puts "Total items without filter" + "#{items.total}"
      item_ids = filter_similar_group_ids(items, item_type, item)
      #puts "Total items after filter" + "#{item_ids.size}"

      #if no of related items less than 5 then increase the variance
      if item_ids.size < 5
        variance = 30
        search_hash = get_item_priority_list(item, variance)
        numeric_hash = search_hash[:numeric_hash]
        boolean_hash = search_hash[:boolean_hash]
        text_hash = search_hash[:text_hash]
        item_type = item.itemtype.itemtype
        items = get_sunspot_related_items(item_type, numeric_hash, boolean_hash, text_hash)
        #puts "Total items after increasing variance without filter" + "#{items.total}"
        item_ids = filter_similar_group_ids(items, item_type, item)
        #puts "Total items after increasing variance after filter" + "#{item_ids.size}"
      end

      #item_id_collection = item_ids.join(',')
      #puts item_id_collection
      item_ids.each do |r_item|
        puts r_item
        related_item = RelatedItem.find_or_create_by_item_id_and_related_item_id(item.id, r_item)
        #related_item.related_item_ids = item_id_collection
        related_item.variance = variance
        related_item.save
      end
      #RelatedItem.create(:item_id => item.id, :related_item_ids => item_id_collection)
    end
  end


  desc "task to set content item relations"

  task :set_item_contents_relations_cache ,:arg1, :needs => :environment do | t, args|
    #ItemContentsRelationsCache.delete_all
    puts args[:arg1]
    arg1 = args[:arg1]
    items = Item.find(:all, :conditions=>["id > ?" , arg1])
    items.each do |item|
      puts item.id
      related_contents = item.related_content
      related_contents.each do |id|
        ItemContentsRelationsCache.create(:item_id => item.id, :content_id => id)
      end
    end
  end
  desc "task to set content item relations"

  task :populate_slug ,:arg1, :arg2, :needs => :environment do | t, args|
    #ItemContentsRelationsCache.delete_all
    puts args[:arg1]
    arg1 = args[:arg1]
    arg2 = args[:arg2]
    items = Item.find(:all,:limit => arg2.to_i, :conditions=>["id > ?" , arg1])
    items.each do |item|
      puts item.id
        item.save
    end
  end

end
