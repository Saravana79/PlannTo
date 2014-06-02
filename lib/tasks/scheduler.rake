desc "Tasks for Heroku scheduler"
task :feed_process => :environment do
  puts "Running Priorities Feed Process, at #{Time.zone.now}"
  Resque.enqueue(FeedProcess, "process_feeds", Time.zone.now, nil, priorities=true)
end

