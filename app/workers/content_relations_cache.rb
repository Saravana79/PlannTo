class ContentRelationsCache
  @queue = :update_content_relations

  def self.perform(content_id, items)
    content = Content.find(content_id)
    content.update_item_contents_relations_cache(content)
    puts "Backend job processed for content item relations cache for content id: #{content.id}"
   end
end
