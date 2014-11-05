require 'rake'
Rake::Task.clear # necessary to avoid tasks being loaded several times in dev mode
PlanNto::Application.load_tasks

class RelatedItemUpdateProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :related_item_update_process

  def self.perform(actual_time)
    log = Logger.new 'log/related_item_update_redis.log'
    #begin
      log.debug "********** Start Processing RelatedItem Update **********"
      log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"
      log.debug "********** Process Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
      log.debug "********** Process Completed at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    Rake::Task["related_items_with_count"].invoke
    # system('rake related_items_with_count[true]')
    #rescue => e
    #  log.debug "Have some problem while executing RelatedItem Update, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "RelatedItem Update").deliver
    #end
    log.debug "********** End Processing RelatedItem Update **********"
    log.debug "\n"
  end
end
