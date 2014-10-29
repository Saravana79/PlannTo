class AutomatedFeedProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :automated_feed_process

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/automated_feed_process.log'
    #begin
    log.debug "********** Start Processing AutomatedFeedProcess **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    FeedUrl.send(method_name)

    #rescue Exception => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing AutomatedFeedProcess **********"
    log.debug "\n"
  end
end
