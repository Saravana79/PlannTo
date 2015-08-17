class AutoUpdateAmazonDeal
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :auto_update_amazon_deal

  def self.perform(actual_time)
    log = Logger.new 'log/auto_update_amazon_deal.log'
    #begin
    log.debug "********** Start Processing auto_update_amazon_deal **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    DealItem.update_amazon_deals()

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing auto_update_amazon_deal **********"
    log.debug "\n"
  end
end
