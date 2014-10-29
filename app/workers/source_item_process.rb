class SourceItemProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :source_item_process

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/source_item_process.log'
    #begin
      log.debug "********** Start Processing SourceItem Suggestion details **********"
      log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
      log.debug "********** Article Content Creation Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
      source_items = Sourceitem.send(method_name)
      log.debug "********** Article Content Creation Completed At - #{Time.zone.now.strftime('%b %d,%Y %r')} - #{source_items} sourceitems updated **********"
    #rescue Exception => e
    #  log.debug "Have some problem while updating SourceItem Suggestion details, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Updating SourceItem Suggestion details").deliver
    #end
    log.debug "********** End Article Content Creation **********"
    log.debug "\n"
  end
end
