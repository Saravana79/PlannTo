namespace :plannto do
   
  task :move_data_to_cache => :environment do
    Item.all.each do |item|
       Rails.cache.write('item:' + item.id.to_s, Item.where(:id => item.id).includes(:item_attributes).last)
    end
  end
  
  task :clear_cache_data =>:environment do
    Item.all.each do |item|
       Rails.cache.delete('item:' + item.id.to_s)

    end
  end
end
