class CookieMatchingProcessBatch
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :cookie_matching_process_batch

  def self.perform(method_name, actual_time, cookie_details)
    log = Logger.new 'log/buying_list_process.log'
    #begin
    log.debug "********** Start Processing CookieMatching **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    CookieMatch.send(method_name, cookie_details)

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing CookieMatching **********"
    log.debug "\n"
  end
end
