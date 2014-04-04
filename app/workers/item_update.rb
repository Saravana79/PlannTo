class ItemUpdate
  @queue = :item_update_process

  def self.perform(method_name, actual_time, item_ids=nil)
    log = Logger.new 'log/item_update_redis.log'
    #begin
      log.debug "********** Start Processing Item Update **********"
      log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
      log.debug "********** Process Started at - #{Time.now.strftime('%b %d,%Y %r')} **********"
      if item_ids.blank?
        updated_items = Item.send(method_name, log)
      else
        updated_items = Item.send(method_name, log, item_ids)
      end
      log.debug "********** Process Completed at - #{Time.now.strftime('%b %d,%Y %r')} **********"
    #rescue Exception => e
    #  log.debug "Have some problem while executing Item Update, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Item Update").deliver
    #end
    log.debug "********** End Processing Item Update **********"
    log.debug "\n"
  end
end
