class ItemAdDetailProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :item_ad_detail_process

  def self.perform(method_name, actual_time, batch_size)
    log = Logger.new 'log/item_ad_detail_process.log'
    #begin
    log.debug "********** Start Processing ItemAdDetail Update **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    ItemAdDetail.send(method_name, log, batch_size)

    #rescue Exception => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing ItemAdDetail Update **********"
    log.debug "\n"
  end
end
