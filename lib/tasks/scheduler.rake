desc "Tasks for Heroku scheduler"
task :feed_process, [:priorities] => :environment do |t, args|
  args.with_defaults(:priorities => "false")
  priorities = args[:priorities]

  puts "Running Priorities Feed Process, at #{Time.zone.now}"
  if $redis.llen("resque:queue:feed_process") == 0
    Resque.enqueue(FeedProcess, "process_feeds", Time.zone.now.utc, nil, priorities=priorities)
  end
end

task :advertisement_process => :environment do
  puts "Running Advertisement ecpm calculation, at #{Time.zone.now}"
  Resque.enqueue(AdvertisementProcess, "calculate_ecpm", Time.zone.now.utc)
end

task :related_item_process => :environment do
  puts "Running Redis Update for RelatedItem, at #{Time.zone.now}"
  Resque.enqueue(RelatedItemUpdateProcess, Time.zone.now)
end

task :item_update => :environment do
  puts "Running Redis Update for Item, at #{Time.zone.now}"
  Resque.enqueue(ItemUpdate, "update_item_details", Time.zone.now)
end

task :item_ad_detail_process => :environment do
  puts "Running ItemAdDetail Update for Items, at #{Time.zone.now}"
  Resque.enqueue(ItemAdDetailProcess, "update_ad_details_for_items", Time.zone.now, 1000)
end

task :aggregated_detail_process_scheduler => :environment do
  puts "Running Queeing Aggregated Process, at #{Time.zone.now}"
  Resque.enqueue(AggregatedDetailProcess, Time.zone.now.utc)
end

task :content_ad_detail_process => :environment do
  puts "Running ContentAdDetail Update for Items, at #{Time.zone.now}"
  if Time.now.wday == 0
    Resque.enqueue(ContentAdDetailProcess, "update_clicks_and_impressions_for_content_ad_details", Time.zone.now.utc, 1000, Time.now)
  end
end

desc "missing url process with example: force=true, process_type=recent, count=200, valid_urls='fonearena.com-gadgetstouse.com,..', invalid_urls='www.cnet.com-www.xxx.com,..', missing_ad=false"
task :missing_url_process, [:force, :process_type, :count, :valid_urls, :invalid_urls, :missing_ad] => :environment do |_, args|
  args.with_defaults(:force => false, :process_type => "recent", :count => 200, :valid_urls => "missingurl:*", :invalid_urls => "download.cnet.com", :missing_ad => false)
  puts "Running Missingurl Process, at #{Time.zone.now}"
  if (args[:force] == "true" || $redis.llen("resque:queue:missing_record_process") == 0)
    Resque.enqueue(MissingurlProcess, "update_by_missing_records", Time.zone.now, args[:force], args[:process_type], args[:count], args[:valid_urls], args[:invalid_urls], args[:missing_ad])
  end
end

task :rtb_budget_update_process => :environment do
  puts "Running RTB Budget Update Process, at #{Time.zone.now}"
  Resque.enqueue(RtbBudgetUpdateProcess, "update_rtb_budget", Time.zone.now)
end

desc "sid ad detail process, Update impressions, clicks and orders"
task :sid_ad_detail_process => :environment do
  puts "Running SidAdDetail process, at #{Time.zone.now}"
  Resque.enqueue(SidAdDetailProcess, "update_clicks_and_impressions_for_sid_ad_details", Time.zone.now, 1000)
end

desc "missing url process for youtube with example: count=100,valid_categories='gaming,science & technology'"
task :youtube_missing_url_process, [:count, :valid_categories] => :environment do |_, args|
  args.with_defaults(:count => 25, :valid_categories => 'science & technology')
  puts "Running youtube_missing_url_process, at #{Time.zone.now}"
  valid_categories = args[:valid_categories]
  valid_categories = valid_categories.to_s.split(",")
  FeedUrl.get_missing_youtube_keys(args[:count], valid_categories)
end

task :remove_missing_keys => :environment do
  puts "remove_missing_keys"
  FeedUrl.remove_missing_keys("missing*")
end

desc "missing url process for collection 'missingurl-toplist'"
task :missing_url_process_top_list => :environment do
  time = Time.zone.now.utc
  if ($redis.llen("resque:queue:missing_record_process") == 0 && (time.hour % 2 == 0))
    Resque.enqueue(MissingUrlProcessTopList, "missing_url_process_top_list", Time.zone.now.utc)
  end
end

desc "Cleanup Keys from redis every week"
task :clean_up_redis_keys => :environment do
  time = Time.zone.now.utc
  if (time.wday == 0)
    Resque.enqueue(CleanUpRedisKeys, "clean_up_redis_keys", Time.zone.now.utc)
  end
end

desc "Create new source category from feed urls every day"
task :update_source_categories => :environment do
  time = Time.zone.now.utc
  Resque.enqueue(SourceCategoryProcess, "check_and_assign_sources_hash_to_source_category_daily", Time.zone.now.utc)
end

desc "Processing Buying List based on user id in redis"
task :buying_list_process => :environment do
  time = Time.zone.now.utc
  Resque.enqueue(BuyingListProcess, "buying_list_process_in_redis", Time.zone.now.utc)
end

desc "Processing Automated FeedProcess"
task :automated_feed_process => :environment do
  time = Time.zone.now.utc
  Resque.enqueue(AutomatedFeedProcess, "automated_feed_process", Time.zone.now.utc)
end

desc "Update hourly budget"
task :update_hourly_budget => :environment do
 Advertisement.check_and_update_hourly_budget()
end