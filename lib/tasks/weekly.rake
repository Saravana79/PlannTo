namespace :plannto do
  require 'global_utilities'
  include GlobalUtilities
  desc "task to find the related items"
   
  task :find_related_items => :environment do
    # include GlobalUtilities
    item_types = Itemtype.where("itemtype IN ('Car', 'Mobile', 'Camera', 'Tablet')").collect(&:id).join(',')
    #puts item_types
    all_items = Item.where("itemtype_id IN (#{item_types})")
    puts all_items.size
    all_items.each do |item|
      #puts item.id
    item = Item.find(item.id)
    variance = 10
    search_hash = get_item_priority_list(item, variance)
    numeric_hash = search_hash[:numeric_hash]
    boolean_hash = search_hash[:boolean_hash]
    text_hash = search_hash[:text_hash]
    item_type = item.itemtype.itemtype    
    items = get_sunspot_related_items(item_type, numeric_hash, boolean_hash, text_hash)

   # puts "Total items without filter" + "#{items.total}"
    item_ids = filter_similar_group_ids(items, item_type, item)
    #puts "Total items after filter" + "#{item_ids.size}"

    #if no of related items less than 5 then increase the variance
    if item_ids.size < 5
        variance = 20
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

    item_id_collection = item_ids.join(',')
    related_item = RelatedItem.find_or_create_by_item_id(item.id)
    related_item.related_item_ids = item_id_collection
    related_item.variance = variance
    related_item.save
    #RelatedItem.create(:item_id => item.id, :related_item_ids => item_id_collection)
    end
  end


end
