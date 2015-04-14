class RemoveDuplicateItems
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :remove_duplicate_items

  def self.perform(method_name, item_ids)
    log = Logger.new 'log/remove_duplicate_items.log'
    #begin
      log.debug "********** Start Processing Remove Duplicate Items **********"
      # log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
      # log.debug "********** Article Content Creation Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
      source_items = Item.send(method_name, item_ids)
      # log.debug "********** Article Content Creation Completed At - #{Time.zone.now.strftime('%b %d,%Y %r')} - #{source_items} sourceitems updated **********"
    #rescue => e
    #  log.debug "Have some problem while updating SourceItem Suggestion details, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Updating SourceItem Suggestion details").deliver
    #end
    log.debug "********** End Remove Duplicate Items **********"
    log.debug "\n"
  end
end
