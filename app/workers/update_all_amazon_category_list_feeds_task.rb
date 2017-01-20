class UpdateAllAmazonCategoryListFeedsTask
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :process_update_all_amazon_category_list_feeds_task

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/list_feeds_update.log'
    #begin
      log.debug "********** Start Processing ListFeedsUpdate with amazon details **********"
      log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
      log.debug "********** ListFeedsUpdate Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
      Product.send(method_name)
      log.debug "********** ListFeedsUpdate Completed At - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    #rescue => e
    #  log.debug "Have some problem while updating SourceItem Suggestion details, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Updating SourceItem Suggestion details").deliver
    #end
    log.debug "********** End ListFeedsUpdate **********"
    log.debug "\n"
  end
end
