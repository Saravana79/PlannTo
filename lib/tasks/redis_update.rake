namespace :redis_update do
  desc 'update redis for items, advertismenets and article_content'
  task :all => :environment do
    # Item update
    log = Logger.new 'log/item_update_redis.log'
    Item.update_item_details(log)

    # advertisements update
    @advertisements = Advertisement.all

    @advertisements.each do |each_advertisement|
      each_advertisement.update_redis_with_advertisement
    end

    # ArticleContent Update
    query = "select c.id,ac.url, c.sub_type, c.itemtype_id, group_concat(distinct(item_id)) as item_ids from article_contents ac inner join contents c on c.id = ac.id
             inner join item_contents_relations_cache icc on icc.content_id = ac.id group by ac.id"

    @contents = Content.find_by_sql(query)

    @contents.each do |each_content|
      if !each_content.url.blank?
        item_ids = each_content.item_ids.split(',')
        item_ids = item_ids.first(50)
        # create content hash in redis-2
        #$redis.HMSET("url:#{self.url}", "item_ids", item_ids, "id", self.id, "article_type", self.sub_type, "itemtype", self.itemtype_id, "count", 0)
        Resque.enqueue(UpdateRedis, "url:#{each_content.url}", "item_ids", item_ids.join(','), "id", each_content.id, "article_type", each_content.sub_type, "itemtype", each_content.itemtype_id, "count", 0)
      end
    end
  end


end