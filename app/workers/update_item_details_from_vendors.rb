class UpdateItemDetailsFromVendors
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :update_item_details_from_vendors

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/update_item_details_from_vendors.log'
    #begin
    log.debug "********** Start Processing Itemdetail Update From Vendors **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    Itemdetail.send(method_name, now_time)

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing Itemdetail Update From Vendors**********"
    log.debug "\n"
  end
end
