namespace :plannto do

  desc "task to find the related items"
   
  task :find_related_items => :environment do
    @item = Item.find(582)
    numeric_hash = Array.new
    boolean_hash = Array.new
    text_hash = Array.new
    @item.priority_specification.each do |item_attribute|
      puts  "#{item_attribute.name} - #{item_attribute.value}  #{item_attribute.attribute_type} "
      if item_attribute.attribute_type == Attribute::NUMERIC
        min_value = item_attribute.lower_search_value
        puts min_value
        max_value = item_attribute.upper_search_value
        puts max_value
        numeric_hash << {:attribute_name => item_attribute.name, :min_value => min_value, :max_value => max_value}
      elsif item_attribute.attribute_type == Attribute::BOOLEAN
        boolean_hash << {:attribute_name => item_attribute.name, :value => item_attribute.value}
      elsif item_attribute.attribute_type == Attribute::TEXT
        text_hash << {:attribute_name => item_attribute.name.to_sym, :value => item_attribute.value}
      end
    end
    item_type = @item.itemtype.itemtype
    
        @items = Sunspot.search(item_type.camelize.constantize) do
      keywords "", :fields => :name      
      dynamic :features do
        numeric_hash.each do |hash|
            with(hash[:attribute_name].to_sym).greater_than(hash[:min_value])
            with(hash[:attribute_name].to_sym).less_than(hash[:max_value])
        end
      end
      dynamic :features_string do
        text_hash.each do |hash|
            with(hash[:attribute_name].to_sym, hash[:value])
        end
        boolean_hash.each do |hash|
            with(hash[:attribute_name].to_sym, hash[:value])
        end
      end
    end

    puts "Total items without filter" + "#{@items.total}"
    item_ids = Array.new
    @items.results.each do |item|      
      if item_type == "Car"
        item_ids << item.id unless item.cargroup.id == @item.cargroup.id
      else
        item_ids << item.id
      end
    end
    puts "FILTERED ITEM IDS AFTER EXCLUDING SIMILAR GROUP ID ITEMS"
    puts item_ids.join(',')
    puts "Total items after filter" + "#{item_ids.size}"
    item_id_collection = item_ids.join(',')
    RelatedItem.create(:item_id => @item.id, :related_item_ids => item_id_collection)
  end


end
