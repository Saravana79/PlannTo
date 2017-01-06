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

task :aggregated_detail_process_scheduler, [:only_ad] => :environment do |_, args|
  args.with_defaults(:only_ad => "true")
  puts "Running Queeing Aggregated Process, at #{Time.zone.now}"
  Resque.enqueue(AggregatedDetailProcess, Time.zone.now.utc, args[:only_ad])
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

task :rtb_budget_update_for_ad_1 => :environment do
  puts "Running RTB Budget Update Process, at #{Time.zone.now}"
  Advertisement.update_ad_1_budget_per_hour()
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
  # if ($redis.llen("resque:queue:missing_url_process_top_list") == 0 && (time.hour % 2 == 0))
  #   Resque.enqueue(MissingUrlProcessTopList, "missing_url_process_top_list", Time.zone.now.utc)
  # end
  Resque.enqueue(MissingUrlProcessTopList, "missing_url_process_top_list", Time.zone.now.utc)
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

desc "Processing Buying List Enqueue based on user id in redis"
task :buying_list_process_enqueue => :environment do
  time = Time.zone.now.utc
  Resque.enqueue(BuyingListProcessEnqueue, "buying_list_process_in_redis_enqueue", Time.zone.now.utc)
end

desc "Processing Buying List based on user id in redis"
task :buying_list_process => :environment do
  time = Time.zone.now.utc
  Resque.enqueue(BuyingListProcess, "buying_list_process_in_redis", Time.zone.now.utc, user_vals=[])
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

desc "temporary rake task"
task :update_buyinglist => :environment do
  buying_lists = $redis_rtb.keys("users:buyinglist:*")

  buying_lists = buying_lists[5250..buying_lists.count]

  buying_lists.each do |buying_list|
    user_id = buying_list.split(":")[2]
    key = "users:buyinglist:#{user_id}"
    begin
      item_ids = $redis_rtb.get(buying_list)
      u_key = "u:ac:#{user_id}"
      u_values = $redis.hgetall(u_key)
      items_count = u_values.select {|k,_| k.include?("_c")}.count
      $redis_rtb.del key
      $redis_rtb.pipelined do
        $redis_rtb.hmset(key, "item_ids", item_ids, "count", items_count)
        $redis_rtb.expire(key, 2.weeks)
      end
    rescue Exception => e
      p "already shared check key => #{key}"
    end
  end
end

desc "amazon price update process"
task :amazon_price_update => :environment do
  Resque.enqueue(AmazonPriceUpdateProcess, "amazon_price_update", Time.zone.now.utc)
end

desc "Update Itemdetail from MySmartPrice"
task :update_item_details_from_vendors => :environment do
  Resque.enqueue(UpdateItemDetailsFromVendors, "update_from_vendors", Time.zone.now.utc)
end

desc "Update top item ids from MySmartPrice"
task :update_top_mysmartprice_item_ids => :environment do
  Resque.enqueue(UpdateTopMysmartpriceItemIds, "update_top_item_ids_from_mysmartprice", Time.zone.now.utc)
end

desc "Update Itemdetail from Flipkart" # Last run Jun 19 9:20 UTC, Hourly job
task :update_item_details_from_vendors_flipkart => :environment do
  Resque.enqueue(UpdateItemDetailsFromVendorsFlipkart, "update_from_vendors_flipkart", Time.zone.now.utc)
end

desc "Processing Cookie Matching Enqueue based on user id in redis"
task :cookie_matching_process_enqueue => :environment do
  time = Time.zone.now.utc
  Resque.enqueue(CookieMatchingProcessEnqueue, "cookie_matching_process_in_redis_enqueue", Time.zone.now.utc)
end

desc "Update bulk cookie matching"
task :bulk_cookie_matching_process => :environment do
  if $redis.llen("resque:queue:bulk_cookie_matching_process") < 1
    Resque.enqueue(BulkCookieMatchingProcess)
  end
end

desc "Update bulk Impression and Click"
task :bulk_impressions_and_clicks_process => :environment do
  if $redis.llen("resque:queue:bulk_create_impression_and_click") < 1
    Resque.enqueue(BulkCreateImpressionAndClick)
  end
end

desc "AdStatisticProcess Update Daily "
task :ad_statistic_process_update => :environment do
  Resque.enqueue(AdStatisticProcessDaily, "process_ad_statistic")
end

desc "Popular vendor products Update Daily "
task :popular_vendor_products_update_daily => :environment do
  Resque.enqueue(PopularVendorProductsUpdate, "update_include_exclude_products_from_vendors")
end

desc "Popular vendor products Update Daily for junglee"
task :popular_vendor_junglee_products_update_daily => :environment do
  Resque.enqueue(PopularVendorJungleeFashionProductUpdate)
end


desc "Orders update from amazon"
task :orders_update_from_amazon_daily => :environment do
  Resque.enqueue(OrderUpdateFromAmazon, "update_order_histories_from_reports", Time.zone.now.utc)
end

desc "Remove mongodb values 1 month old"
task :remove_mongodb_values => :environment do
  Resque.enqueue(RemoveOldMongodbValue, "remove_old_mongodb_values")
end

desc "City State and Place process"
task :city_state_and_place_process => :environment do
  Place.city_state_place_process()
end

desc "Updating Itemdetails from auto"
task :update_itemdetails_from_auto => :environment do
  Itemdetail.update_itemdetails_from_auto()
end

desc "Manually update amazon today deal"
task :update_amazon_daily_deal => :environment do
  Itemdetail.amazon_daily_deal_update()
end

desc "Processing Buying List Enqueue based on user id in redis"
task :article_content_auto_process_enqueue => :environment do
  time = Time.zone.now.utc
  Resque.enqueue(ArticleContentAutoProcessEnqueue, "article_content_auto_process_enqueue_in_redis", Time.zone.now.utc)
end

desc "Processing Buying List based on user id in redis"
task :article_content_auto_process => :environment do
  time = Time.zone.now.utc
  Resque.enqueue(ArticleContentAutoProcess, "article_content_auto_process_in_redis", Time.zone.now.utc, article_contents=[])
end

desc "Update Sourceitem for autoportals"
task :update_source_item_for_auto_portals => :environment do
  Resque.enqueue(UpdateSourceitemForAutoportal, Time.zone.now.utc)
end

desc "Auto update amazon deal"
task :auto_update_amazon_deal => :environment do
  Resque.enqueue(AutoUpdateAmazonDeal, Time.zone.now.utc)
end

desc "Auto update source item to itemdetail for paytm"
task :auto_update_itemdetail_sourceitem_for_paytm => :environment do
  Resque.enqueue(AutoUpdateItemdetailFromSourceitemForPaytm, Time.zone.now.utc)
end

desc "Auto update top itemdetail for paytm"
task :auto_update_top_itemdetail_for_paytm => :environment do
  Resque.enqueue(AutoUpdateTopItemdetailForPaytm, Time.zone.now.utc)
end

desc "Update AggregatedImpression from redis for widgets"
task :update_aggregated_impression_from_redis => :environment do
  Resque.enqueue(UpdateAggregatedImpressionFromRedis, Time.zone.now.utc)
end

desc "Update AggregatedImpressionByType from mongodb"
task :update_aggregated_impression_from_mongodb => :environment do
  Resque.enqueue(UpdateAggregatedImpressionFromMongodb, Time.zone.now.utc)
  Resque.enqueue(UpdateAggregatedImpressionFromMongodb, Date.yesterday)
end

desc "Update ConversionPixelDetail from based on click for ad 83"
task :update_conversion_pixel_detail_from_click => :environment do
  Resque.enqueue(UpdateConversionPixelDetailFromClick, Time.zone.now.utc)
end

desc "Create New arrivals from amazon to source item "
task :create_source_item_for_new_arrivals_from_amazon => :environment do
  Resque.enqueue(CreateSourceItemForNewArrivalFromAmazon, "create_source_item_for_new_arrivals_from_amazon")
end

desc "Create Sourceitem for amazon ec from amazon feeds"
task :create_source_item_for_amazon_ec => :environment do
  Resque.enqueue(SourceItemUpdateWithAmazonEc, "create_source_item_for_amazon_ec", Time.zone.now.utc)
end

desc "Update amazon list feeds"
task :update_all_amazon_category_list_feeds_task => :environment do
  Resque.enqueue(UpdateAllAmazonCategoryListFeedsTask, "update_all_amazon_category_list_feeds", Time.zone.now.utc)
end