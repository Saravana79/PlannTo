class AutoUpdateItemdetailFromSourceitemForPaytm
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :auto_update_item_detail_from_source_item_for_paytm

  def self.perform(actual_time)
    log = Logger.new 'log/auto_update_item_detail_from_source_item_for_paytm.log'
    #begin
    log.debug "********** Start Processing auto_update_sourceitem_to_paytm **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    # if (actual_time.day % 3) == 0
    #   Resque.enqueue(AutoUpdateSourceitemFromPaytm, Time.zone.now.utc)
    # end

    Sourceitem.process_source_item_update_paytm()

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing auto_update_item_detail_from_source_item_for_paytm **********"
    log.debug "\n"
  end
end
