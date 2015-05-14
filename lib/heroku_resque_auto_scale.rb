require 'heroku-api'

module HerokuResqueAutoScale
  module Scaler
    class << self
      @@heroku = Heroku::API.new(:username => ENV['HEROKU_USER'], :password => ENV['HEROKU_PASSWORD'])
      # @@heroku = Heroku::API.new(:username => "siva@plannto.com", :password => "sivaplannto")

      def workers
        # @@heroku.info(ENV['HEROKU_APP'])[:workers].to_i
        response = @@heroku.get_ps("plannto").body
        response.select {|e| e["process"].include?("worker")}.count
      end

      def webs
        # @@heroku.info(ENV['HEROKU_APP'])[:workers].to_i
        response = @@heroku.get_ps("plannto").body
        response.select {|e| e["process"].include?("web")}.count
      end

      def set_workers(qty, type="worker")
        @@heroku.post_ps_scale(ENV['HEROKU_APP'], type, qty)
      end

      def job_count
        rescue_count = Resque.info[:pending].to_i
        impression_count = $redis.llen("resque:queue:create_impression_and_click")
        cookie_match_count = $redis.llen("resque:queue:cookie_matching_process")
        count = rescue_count - impression_count - cookie_match_count
        count < 0 ? 2 : count
      end

      def working_job_count
        Resque.info[:working].to_i
      end
    end
  end

  def after_perform_scale_down(*args)
    # TODO:have to implement for become 0 worker
    # return if !$redis.get("auto_scaled_heroku_worker").blank?
    # Nothing fancy, just shut everything down if we have no pending jobs
    # and one working job (which is this job)
    # Scaler.set_workers(0) if Scaler.job_count.zero? && Scaler.working_job_count == 0
  end

  def after_enqueue_scale_workers(*args)
    if $redis.get("auto_scaled_heroku_web").blank?
      #Increase and Decrease web
      time = Time.now.localtime.hour
      new_web_count = 2

      if time == 22
        web_count = Scaler.webs
        new_web_count = web_count - 1
      elsif time == 0
        web_count = Scaler.webs
        new_web_count = web_count - 1
      elsif time == 8
        web_count = Scaler.webs
        new_web_count = web_count + 1
      elsif time == 10
        web_count = Scaler.webs
        new_web_count = web_count + 1
      end

      if new_web_count > 2
        Scaler.set_workers(new_web_count, "web")

        $redis.pipelined do
          $redis.set("auto_scaled_heroku_web", "true")
          $redis.expire("auto_scaled_heroku_web", 1.hour)
        end
      end
    end

    return if !$redis.get("auto_scaled_heroku_worker").blank?

    $redis.pipelined do
      $redis.set("auto_scaled_heroku_worker", "true")
      $redis.expire("auto_scaled_heroku_worker", 30.minutes)
    end

    job_count = Scaler.job_count
    workers_count = Scaler.workers

    min_worker = $redis.get("resque_min_worker_count").to_i

    [
        {
            :workers => min_worker, # This many workers
            :job_count => 1 # For this many jobs or more, until the next level
        },
        {
            :workers => min_worker+1,
            :job_count => 3
        },
        {
            :workers => min_worker+2,
            :job_count => 100
        },
        {
            :workers => min_worker+3,
            :job_count => 1000
        },
        {
            :workers => min_worker+4,
            :job_count => 5000
        }
    ].reverse_each do |scale_info|
      # Run backwards so it gets set to the highest value first
      # Otherwise if there were 70 jobs, it would get set to 1, then 2, then 3, etc
      # If we have a job count greater than or equal to the job limit for this scale info
      if job_count >= scale_info[:job_count]
        # Set the number of workers unless they are already set to a level we want. Don't scale down here!
        if workers_count != scale_info[:workers]
          Scaler.set_workers(scale_info[:workers])
        end
        break # We've set or ensured that the worker count is high enough
      end
    end
  end
end