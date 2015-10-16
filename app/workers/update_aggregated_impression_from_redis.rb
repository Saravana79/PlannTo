class UpdateAggregatedImpressionFromRedis
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :update_aggregated_impression_from_redis

  def self.perform(actual_time)
    log = Logger.new 'log/update_aggregated_impression_from_redis.log'
    #begin
    log.debug "********** Start Processing Itemdetail Update From Vendors **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    AggregatedImpression.send("update_from_redis_for_widget")

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing update_aggregated_impression_from_redis**********"
    log.debug "\n"
  end
end
