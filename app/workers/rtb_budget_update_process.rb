class RtbBudgetUpdateProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  @queue = :rtb_budget_update_process

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/rtb_budget_update_process.log'
    #begin
    log.debug "********** Start Processing Rtb Budget Update **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    Advertisement.send(method_name, log, actual_time)

    #rescue Exception => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing Rtb Budget Update **********"
    log.debug "\n"
  end
end
