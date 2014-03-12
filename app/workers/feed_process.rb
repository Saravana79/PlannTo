class FeedProcess
  @queue = :feed_process

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/feed_process.log'
    begin
      log.debug "********** Start Processing Feeds **********"
      log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
      log.debug "********** Process Started at - #{Time.now.strftime('%b %d,%Y %r')} **********"
      created_feed_urls = Feed.send(method_name)
      log.debug "********** Process Completed at - #{Time.now.strftime('%b %d,%Y %r')} - #{created_feed_urls} feed_urls created **********"
    rescue Exception => e
      log.debug e
    end
    log.debug "********** End Processing Feed **********"
    log.debug "\n"
  end
end
