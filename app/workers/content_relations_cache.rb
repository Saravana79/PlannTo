class ContentRelationsCache
  extend HerokuResqueAutoScale if Rails.env.production?
  @queue = :update_content_relations

  def self.perform(content_id, items, update=false)
    content = Content.find(content_id)
    if update == true
      #destroy old items
      #check if new item ids and old item ids of content is not same
      #if not same then delete the old records in contentitemsrelationscache table with content.id
      #and then run content.save_content_relations_cache(items)

    end
    content.update_item_contents_relations_cache(content)
    puts "Backend job processed for content item relations cache for content id: #{content.id}"
   end
end
