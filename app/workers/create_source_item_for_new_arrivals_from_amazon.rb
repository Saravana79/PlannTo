class CreateSourceItemForNewArrivalFromAmazon
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :create_source_item_for_new_arrivals_from_amazon_process

  def self.perform(method_name, actual_time, batch_size, now_time)
    log = Logger.new 'log/create_source_item_for_new_arrivals_from_amazon_process.log'
    #begin
    log.debug "********** Start Creating new source item for amazon new arrivals **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    Sourceitem.send(method_name, now_time)

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing ContentAdDetail Update **********"
    log.debug "\n"
  end
end
