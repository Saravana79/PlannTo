class ArticleContentProcess
  @queue = :article_content_process

  def self.perform(method_name, actual_time, param, user_id, remote_ip)
    log = Logger.new 'log/article_content_process.log'
    begin
      log.debug "********** Start Processing Article Content Creation **********"
      log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
      log.debug "********** Article Content Creation Started at - #{Time.now.strftime('%b %d,%Y %r')} **********"
      param = JSON.parse(param)
      created_feed_urls = ArticleContent.send(method_name, param, user_id, remote_ip)
      log.debug "********** Article Content Creation Completed At - #{Time.now.strftime('%b %d,%Y %r')} - Response - #{created_feed_urls} **********"
    rescue Exception => e
      log.debug "Have some problem while executing Article Content Creation, please find the error below"
      log.debug e
      NotificationMailer.resque_process_failure(e, e.backtrace, log, "Article Content Creation").deliver
    end
    log.debug "********** End Article Content Creation **********"
    log.debug "\n"
  end
end
