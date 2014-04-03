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
  #  Resque.enqueue(FeedProcess, job, Time.now)
  #end

  #every(1.minutes, 'process_feeds')

  every(1.day, 'Queeing Feed Process', :at => '00:00', :tz => "Asia/Kolkata") do
    puts "Running Feed Process, at #{Time.now}"
      Resque.enqueue(FeedProcess, "process_feeds", Time.now)
  end

  every(1.day, 'Queeing Advertisement ecpm calculation', :at => '02:00', :tz => "Asia/Kolkata") do
    puts "Running Advertisement ecpm calculation, at #{Time.now}"
    Resque.enqueue(AdvertisementProcess, "calculate_ecpm", Time.now)
  end

  every(1.day, 'Queeing Redis Update for RelatedItem', :at => '03:00', :tz => "Asia/Kolkata") do
    puts "Running Redis Update for RelatedItem, at #{Time.now}"
    Resque.enqueue(RelatedItemUpdateProcess, Time.now)
  end

  every(1.day, 'Queeing Redis Update for Item', :at => '05:00', :tz => "Asia/Kolkata") do
    puts "Running Redis Update for Item, at #{Time.now}"
    Resque.enqueue(ItemUpdate, "update_item_details", Time.now)
  end

  #every(3.minutes, 'less.frequent.job')
  #every(1.hour, 'hourly.job')
  #
  #every(1.day, 'midnight.job', :at => '00:00')
end