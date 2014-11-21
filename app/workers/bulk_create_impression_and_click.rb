class BulkCreateImpressionAndClick
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :bulk_create_impression_and_click

  def self.perform
    log = Logger.new 'log/bulk_create_impression_and_click.log'
    #begin
    log.debug "********** Start Processing BulkCreateImpressionAndClick **********"
    log.debug "********** BulkCreateImpressionAndClick Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    Advertisement.send("bulk_process_cookie_matching")
    log.debug "********** BulkCreateImpressionAndClick Completed at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing BulkCreateImpressionAndClick **********"
    log.debug "\n"
  end
end
