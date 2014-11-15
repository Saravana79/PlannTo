class CookieMatchingProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :cookie_matching_process

  def self.perform(method_name, valid_param)
    log = Logger.new 'log/cookie_matching_process.log'
    #begin
    log.debug "********** Start Processing CookieMatch **********"
    log.debug "********** CookieMatch Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    advertisements = CookieMatch.send(method_name, valid_param)
    log.debug "********** CookieMatch Completed at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing CookieMatch **********"
    log.debug "\n"
  end
end
