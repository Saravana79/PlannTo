class AdvertisementProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :advertisement_process

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/advertisement_process.log'
    #begin
      log.debug "********** Start Processing calculate ecpm **********"
      log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
      log.debug "********** Calculate ecpm Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
      advertisements = Advertisement.send(method_name)
      log.debug "********** Calculate ecpm Completed at - #{Time.zone.now.strftime('%b %d,%Y %r')} - #{advertisements} Advertisements updated **********"
    #rescue Exception => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing calculate ecpm **********"
    log.debug "\n"
  end
end
