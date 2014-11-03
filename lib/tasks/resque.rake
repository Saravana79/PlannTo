require "resque/tasks"
require 'resque/scheduler/tasks'

task "resque:setup" => :environment do
  # ENV['QUEUE'] = '*'
  # Resque.after_fork do |job|
  #   ActiveRecord::Base.establish_connection
  # end
  # Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }

  before_fork do |server, worker|
    # Disconnect since the database connection will not carry over
    if defined? ActiveRecord::Base
      ActiveRecord::Base.connection.disconnect!
    end

    if defined?(Resque)
      Resque.redis.quit
      Rails.logger.info('Disconnected from Redis')
    end
  end

  after_fork do |server, worker|
    # Start up the database connection again in the worker
    if defined?(ActiveRecord::Base)
      ActiveRecord::Base.establish_connection
    end

    if defined?(Resque)
      Resque.redis = $redis
      Rails.logger.info('Connected to Redis')
    end
  end

end

desc "Alias for resque:work (To run workers on Heroku)"
task "jobs:work" => "resque:work"