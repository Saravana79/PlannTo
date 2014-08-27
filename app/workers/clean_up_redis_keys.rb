class CleanUpRedisKeys
  @queue = :clean_up_redis_keys

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/clean_up_redis_keys.log'
    #begin
    log.debug "********** Start Processing CleanUpRedisKeys **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    FeedUrl.send(method_name)

    #rescue Exception => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing Missingurl **********"
    log.debug "\n"
  end
end
