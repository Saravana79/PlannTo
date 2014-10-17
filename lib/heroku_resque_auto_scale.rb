require 'heroku-api'

module HerokuResqueAutoScale
  module Scaler
    class << self
      @@heroku = Heroku::API.new(:username => ENV['HEROKU_USER'], :password => ENV['HEROKU_PASSWORD'])
      # @@heroku = Heroku::API.new(:username => "siva@plannto.com", :password => "sivaplannto")
      p 111111111111
      p @@heroku

      def workers
        p 22222222222
        # @@heroku.info(ENV['HEROKU_APP'])[:workers].to_i
        response = @@heroku.get_ps("plannto").body
        response.select {|e| e["process"].include?("worker")}.count
      end

      def set_workers(qty)
        @@heroku.post_ps_scale(ENV['HEROKU_APP'], "worker", qty)
      end

      def job_count
        Resque.info[:pending].to_i
      end

      def working_job_count
        Resque.info[:working].to_i
      end
    end
  end

  def after_perform_scale_down(*args)
    # Nothing fancy, just shut everything down if we have no pending jobs
    # and one working job (which is this job)
    Scaler.set_workers(0) if Scaler.job_count.zero? && Scaler.working_job_count == 0
  end

  def after_enqueue_scale_workers(*args)
    p 88888888888888888888888888888888888888
    p "calling"

    [
        {
            :workers => 1, # This many workers
            :job_count => 1 # For this many jobs or more, until the next level
        },
        {
            :workers => 2,
            :job_count => 5
        },
        {
            :workers => 3,
            :job_count => 100
        },
        {
            :workers => 4,
            :job_count => 1000
        },
        {
            :workers => 5,
            :job_count => 5000
        }
    ].reverse_each do |scale_info|
      # Run backwards so it gets set to the highest value first
      # Otherwise if there were 70 jobs, it would get set to 1, then 2, then 3, etc

      # If we have a job count greater than or equal to the job limit for this scale info
      if Scaler.job_count >= scale_info[:job_count]
        # Set the number of workers unless they are already set to a level we want. Don't scale down here!
        p scale_info[:workers]
        p Scaler.workers
        if Scaler.workers < scale_info[:workers]
          Scaler.set_workers(scale_info[:workers])
        end
        break # We've set or ensured that the worker count is high enough
      end
    end
  end
end