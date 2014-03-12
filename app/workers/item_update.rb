class ItemUpdate
  @queue = :item_update_process

  def self.perform(method_name, actual_time)
    log = Logger.new 'log/item_update_redis.log'
    begin
      log.debug "********** Start Processing Item Update **********"
      log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
      log.debug "********** Process Started at - #{Time.now.strftime('%b %d,%Y %r')} **********"
      updated_items = Item.send(method_name)
      log.debug "********** Process Completed at - #{Time.now.strftime('%b %d,%Y %r')} **********"
    rescue Exception => e
      log.debug "Have some problem while executing Item Update, please find the error below"
      log.debug e
      NotificationMailer.resque_process_failure(e, log, "Item Update").deliver
    end
    log.debug "********** End Processing Item Update **********"
    log.debug "\n"
  end
end
