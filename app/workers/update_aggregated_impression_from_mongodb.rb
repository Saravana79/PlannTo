class UpdateAggregatedImpressionFromMongodb
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :update_aggregated_impression_from_mongodb

  def self.perform(actual_time)
    log = Logger.new 'log/update_aggregated_impression_from_mongodb.log'
    #begin
    log.debug "********** Start Processing Aggregated Impression By Type From Mongodb **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    AggregatedImpressionByType.send("update_user_count_for_items_ids")

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing Aggregated Impression By Type From Mongodb **********"
    log.debug "\n"
  end
end
