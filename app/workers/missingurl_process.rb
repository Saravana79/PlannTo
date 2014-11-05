class MissingurlProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :missing_record_process

  def self.perform(method_name, actual_time, force, process_type, count, valid_urls, invalid_urls, missing_ad)
    log = Logger.new 'log/missing_record_process.log'
    #begin
    log.debug "********** Start Processing Missingurl **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    valid_urls = valid_urls.to_s.split("-")
    invalid_urls = invalid_urls.to_s.split("-")

    if force.to_s == "true"
      FeedUrl.send(method_name, log, process_type, count, valid_urls, invalid_urls, missing_ad)
    elsif (now_time.hour % 2 == 0)
      FeedUrl.send(method_name, log, process_type, count, valid_urls, invalid_urls, missing_ad)
    end

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing Missingurl **********"
    log.debug "\n"
  end
end
