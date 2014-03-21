class FeedProcess
  @queue = :feed_process

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/feed_process.log'
    begin
      log.debug "********** Start Processing Feeds **********"
      log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
      log.debug "********** Feed Process Started at - #{Time.now.strftime('%b %d,%Y %r')} **********"
      created_feed_urls = Feed.send(method_name)
      log.debug "********** Feed Process Completed at - #{Time.now.strftime('%b %d,%Y %r')} - #{created_feed_urls} feed_urls created **********"
    rescue Exception => e
      log.debug "Have some problem while executing feed process, please find the error below"
      log.debug e
      NotificationMailer.resque_process_failure(e, log, "Feed Process").deliver
      NotificationMailer.resque_process_failure(e, e.backtrace, log, "Feed Process").deliver
    end
    log.debug "********** End Processing Feed **********"
    log.debug "\n"
  end
end
