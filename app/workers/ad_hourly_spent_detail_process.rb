class AdHourlySpentDetailProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :ad_hourly_spent_detail_process

  def self.perform(method_name, param)
    log = Logger.new 'log/ad_hourly_spent_detail_process.log'
    #begin
    log.debug "********** Start Processing ad_hourly_spent_detail_process **********"
    log.debug "**********  AdHourlySpentDetailProcess Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    AdHourlySpentDetail.send(method_name,param)
    log.debug "********** AdHourlySpentDetailProcess Completed at - #{Time.zone.now.strftime('%b %d,%Y %r')}  **********"
    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing calculate ecpm **********"
    log.debug "\n"
  end
end
