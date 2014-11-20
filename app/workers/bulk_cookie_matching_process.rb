class BulkCookieMatchingProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :bulk_cookie_matching_process

  def self.perform
    log = Logger.new 'log/bulk_cookie_matching_process.log'
    #begin
    log.debug "********** Start Processing CookieMatch **********"
    log.debug "********** CookieMatch Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    advertisements = CookieMatch.send("bulk_process_cookie_matching")
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
