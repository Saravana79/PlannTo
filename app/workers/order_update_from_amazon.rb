class OrderUpdateFromAmazon
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :order_update_from_amazon

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/order_update_from_amazon.log'
    #begin
    log.debug "********** Start Processing Amazon Order Update **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
    log.debug "********** Calculate ecpm Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    OrderHistory.send(method_name)
    log.debug "********** Calculate ecpm Completed at - #{Time.zone.now.strftime('%b %d,%Y %r')}  Advertisements updated **********"
    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing Amazon Order Update **********"
    log.debug "\n"
  end
end
