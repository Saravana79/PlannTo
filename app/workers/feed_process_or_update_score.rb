class FeedProcessOrUpdateScore
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :feed_process_or_update_score

  def self.perform(actual_time)
    log = Logger.new 'log/feed_process.log'
    #begin
    log.debug "********** Start Processing feed_process_or_update_score **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
    log.debug "********** Feed Process Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    FeedUrl.send("auto_save_or_update_score_feed_urls")

    log.debug "********** Feed Process Completed at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    #rescue => e
    #  log.debug "Have some problem while executing feed process, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Feed Process").deliver
    #end
    log.debug "********** End Processing Feed **********"
    log.debug "\n"
  end
end
