require "resque/tasks"

task "resque:setup" => :environment do
  # ENV['QUEUE'] = '*'
  # Resque.after_fork do |job|
  #   ActiveRecord::Base.establish_connection
  # end
  Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
end

task "resque:pause" => :environment do
  Resque.redis.set "resque_paused", true
  puts "Resque paused."
end

task "resque:resume" => :environment do
  Resque.redis.set "resque_paused", false
  puts "Resque resumed."
end

task "resque:paused" => :environment do
  paused = Resque.redis.get("resque_paused") == 'true'
  puts "Resque paused: #{paused}"
end

desc "Alias for resque:work (To run workers on Heroku)"
task "jobs:work" => "resque:work"
