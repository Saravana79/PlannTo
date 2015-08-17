class UpdateSourceitemForAutoportal
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :update_source_item_for_autoportals

  def self.perform(actual_time)
    log = Logger.new 'log/update_source_item_for_autoportals.log'
    #begin
    log.debug "********** Start Processing update_source_item_for_autoportals **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    Sourceitem.send("update_source_item_for_auto_portals")

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing update_source_item_for_autoportals **********"
    log.debug "\n"
  end
end
