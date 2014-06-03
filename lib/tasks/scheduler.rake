desc "Tasks for Heroku scheduler"
task :feed_process => :environment do
  puts "Running Priorities Feed Process, at #{Time.zone.now}"
  Resque.enqueue(FeedProcess, "process_feeds", Time.zone.now, nil, priorities=true)
end

task :advertisement_process => :environment do
  puts "Running Advertisement ecpm calculation, at #{Time.zone.now}"
  Resque.enqueue(AdvertisementProcess, "calculate_ecpm", Time.zone.now)
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
  Resque.enqueue(AggregatedDetailProcess, Time.zone.now)
end

task :content_ad_detail_process => :environment do
  puts "Running ContentAdDetail Update for Items, at #{Time.zone.now}"
  Resque.enqueue(ContentAdDetailProcess, "update_ad_details_for_contents", Time.zone.now, 1000)
end

task :missing_url_process => :environment do
  puts "Running Missingurl Process, at #{Time.zone.now}"
  Resque.enqueue(MissingurlProcess, "update_by_missing_records", Time.zone.now)
end