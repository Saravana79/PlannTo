class FeedProcess
  @queue = :feed_process

  def self.perform(method_name, actual_time, feed_id=nil, priorities="false")
    p priorities
    log = Logger.new 'log/feed_process.log'
    #begin
      log.debug "********** Start Processing Feeds **********"
      log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
      log.debug "********** Feed Process Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    if priorities.to_s == "true"
      feed_ids = Feed.where("priorities = 1").map(&:id)
      created_feed_urls = Feed.send(method_name, feed_ids)
    else
      feed_ids = feed_id.blank? ? [] : [feed_id]
      created_feed_urls = Feed.send(method_name, feed_ids)
    end

      log.debug "********** Feed Process Completed at - #{Time.zone.now.strftime('%b %d,%Y %r')} - #{created_feed_urls} feed_urls created **********"
    #rescue Exception => e
    #  log.debug "Have some problem while executing feed process, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Feed Process").deliver
    #end
    log.debug "********** End Processing Feed **********"
    log.debug "\n"
  end
end
