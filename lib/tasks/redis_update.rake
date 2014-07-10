namespace :redis_update do
  desc 'update redis for items, advertismenets and article_content'
  task :all, [:batch_size] => :environment do |t, args|
    args.with_defaults(:batch_size => 2000)
    batch_size = args[:batch_size].to_i
    # Item update
    log = Logger.new 'log/item_update_redis.log'
    Item.update_item_details(log, batch_size)

    # advertisements update
    Advertisement.find_in_batches(:batch_size => batch_size) do |advertisements|
      advertisements.each do |each_advertisement|
        each_advertisement.update_redis_with_advertisement
      end
    end

    # ArticleContent Update
    query = "select c.id,ac.url, c.sub_type, c.itemtype_id, group_concat(distinct(item_id)) as rel_item_ids from article_contents ac inner join contents c on c.id = ac.id
             inner join item_contents_relations_cache icc on icc.content_id = ac.id group by ac.id"

    # Using paginate_by_sql to batches the records

    page = 1
    begin
      contents = Content.paginate_by_sql(query, :page => page, :per_page => batch_size)
      contents.each do |each_content|
        if !each_content.url.blank?
          rel_item_ids = each_content.rel_item_ids.split(',')
          rel_item_ids = rel_item_ids.first(50)
          # create content hash in redis-2
          #$redis.HMSET("url:#{self.url}", "item_ids", item_ids, "id", self.id, "article_type", self.sub_type, "itemtype", self.itemtype_id, "count", 0)
          Resque.enqueue(UpdateRedis, "url:#{each_content.url}", "item_ids", rel_item_ids.join(','), "id", each_content.id, "article_type", each_content.sub_type, "itemtype", each_content.itemtype_id, "count", 0)
        end
      end

      page += 1
    end while !contents.empty?
  end

  desc "One time task to load item_ids to content"
  task :load_item_ids => :environment do
    batch_size = 1000
    query = "select c.id,ac.url, c.sub_type, c.itemtype_id, group_concat(distinct(item_id)) as item_ids from article_contents ac inner join contents c on c.id = ac.id inner join item_contents_relations_cache icc on icc.content_id = ac.id group by ac.id"

# Using paginate_by_sql to batches the records

    page = 1
    begin
      contents = Content.paginate_by_sql(query, :page => page, :per_page => batch_size)
      contents.each do |each_content|
        p each_content.url
        if !each_content.url.blank?
          rel_item_ids = each_content.rel_item_ids.split(',')
          rel_item_ids = rel_item_ids.first(50)
          Resque.enqueue(UpdateRedis, "url:#{each_content.url}", "item_ids", rel_item_ids.join(','))
        end
      end
      page += 1
    end while !contents.empty?
  end

end