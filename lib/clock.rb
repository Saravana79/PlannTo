require 'clockwork'
require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)

module Clockwork

  #handler do |job|
  #  puts "Running #{job}"
  #end

  # handler receives the time when job is prepared to run in the 2nd argument
  #handler do |job, time|
  #  puts "Running #{job}, at #{time}"
  #  Resque.enqueue(FeedProcess, job, Time.zone.now)
  #end

  #every(1.minutes, 'process_feeds')

  every(1.day, 'Queeing Feed Process', :at => '00:00', :tz => "Asia/Kolkata") do
    puts "Running Feed Process, at #{Time.zone.now}"
      Resque.enqueue(FeedProcess, "process_feeds", Time.zone.now)
  end

  every(1.day, 'Queeing Advertisement ecpm calculation', :at => '02:00', :tz => "Asia/Kolkata") do
    puts "Running Advertisement ecpm calculation, at #{Time.zone.now}"
    Resque.enqueue(AdvertisementProcess, "calculate_ecpm", Time.zone.now)
  end

  every(1.day, 'Queeing Redis Update for RelatedItem', :at => '03:00', :tz => "Asia/Kolkata") do
    puts "Running Redis Update for RelatedItem, at #{Time.zone.now}"
    Resque.enqueue(RelatedItemUpdateProcess, Time.zone.now)
  end

  every(1.day, 'Queeing Redis Update for Item', :at => '05:00', :tz => "Asia/Kolkata") do
    puts "Running Redis Update for Item, at #{Time.zone.now}"
    Resque.enqueue(ItemUpdate, "update_item_details", Time.zone.now)
  end

  every(1.day, 'Queeing ItemAdDetail Update for Items', :at => '06:00', :tz => "Asia/Kolkata") do
    puts "Running ItemAdDetail Update for Items, at #{Time.zone.now}"
    Resque.enqueue(ItemAdDetailProcess, "update_ad_details_for_items", Time.zone.now, 1000)
  end

  every(1.hour, 'Queeing Aggregated Process') do
    puts "Running Queeing Aggregated Process, at #{Time.zone.now}"
    Resque.enqueue(AggregatedDetailProcess, Time.zone.now)
  end

  # every(2.hours, 'Queeing Feed Process') do
  #   puts "Running Priorities Feed Process, at #{Time.zone.now}"
  #   Resque.enqueue(FeedProcess, "process_feeds", Time.zone.now, nil, priorities=true)
  end

  every(1.day, 'Queeing ContentAdDetail Update for Items', :at => '07:00', :tz => "Asia/Kolkata") do
    puts "Running ContentAdDetail Update for Items, at #{Time.zone.now}"
    Resque.enqueue(ContentAdDetailProcess, "update_ad_details_for_contents", Time.zone.now, 1000)
  end

  every(6.hours, 'Queeing Missingurl Process from Redis') do
    puts "Running Missingurl Process, at #{Time.zone.now}"
    Resque.enqueue(MissingurlProcess, "update_by_missing_records", Time.zone.now)
  end

  #every(3.minutes, 'less.frequent.job')
  #every(1.hour, 'hourly.job')
  #
  #every(1.day, 'midnight.job', :at => '00:00')
end