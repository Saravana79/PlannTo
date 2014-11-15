class GenerateReport
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :generate_report_process

  def self.perform(method_name, ad_report_id, actual_time)
    log = Logger.new 'log/generate_report_process.log'
    #begin
    log.debug "********** Start Processing generate_report_process **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
    log.debug "********** generate_report_process Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    advertisements = Advertisement.send(method_name, ad_report_id)
    log.debug "********** generate_report_process Completed at - #{Time.zone.now.strftime('%b %d,%Y %r')} - #{advertisements} Advertisements **********"
    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing generate_report_process **********"
    log.debug "\n"
  end
end
