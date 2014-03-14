require 'clockwork'
require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)

module Clockwork

  #configure do |config|
  #  config[:logger] = Logger.new("log/clockwork.log")
  #end

  #handler do |job|
  #  puts "Running #{job}"
  #end

  # handler receives the time when job is prepared to run in the 2nd argument
  #handler do |job, time|
  #  puts "Running #{job}, at #{time}"
  #  Resque.enqueue(FeedProcess, job, Time.now)
  #end

  #every(1.minutes, 'process_feeds')

  #every(1.day, 'Queeing Feed Process', :at => '00:00') do
  every(1.day, 'Queeing Feed Process', :at => '14:58') do # testing
    puts "Running Feed Process, at #{Time.now}"
      Resque.enqueue(FeedProcess, "process_feeds", Time.now)
  end

  every(1.day, 'Queeing Redis Update for Item', :at => '04:00') do
    puts "Running Redis Update for Item, at #{Time.now}"
    Resque.enqueue(ItemUpdate, "update_item_details", Time.now)
  end

  #every(3.minutes, 'less.frequent.job')
  #every(1.hour, 'hourly.job')
  #
  #every(1.day, 'midnight.job', :at => '00:00')
end