class ContentAdDetailProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :content_ad_detail_process

  def self.perform(method_name, actual_time, batch_size, now_time)
    log = Logger.new 'log/content_ad_detail_process.log'
    #begin
    log.debug "********** Start Processing ContentAdDetail **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    ContentAdDetail.send(method_name, log, batch_size, now_time)

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing ContentAdDetail Update **********"
    log.debug "\n"
  end
end
