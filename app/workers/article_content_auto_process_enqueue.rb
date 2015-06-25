class ArticleContentAutoProcessEnqueue
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :article_content_auto_process_enqueue

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/article_content_auto_process_enqueue.log'
    #begin
    log.debug "********** Start Processing ArticleContentAutoProcessEnqueue **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    ArticleContent.send(method_name)

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing ArticleContentAutoProcessEnqueue **********"
    log.debug "\n"
  end
end
