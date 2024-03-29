class BuyingListProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :buying_list_process

  def self.perform(method_name, actual_time, user_vals)
    log = Logger.new 'log/buying_list_process.log'
    #begin
    log.debug "********** Start Processing BuyingList **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    Item.send(method_name, user_vals)

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing BuyingList **********"
    log.debug "\n"
  end
end
