class UpdateConversionPixelDetailFromClick
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :update_conversion_pixel_detail_from_click_queue

  def self.perform(actual_time)
    log = Logger.new 'log/update_conversion_pixel_detail_from_click_queue.log'
    #begin
    log.debug "********** Start Processing Update Conversion Pixel Detail **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    ConversionPixelDetail.send("update_conversion_pixel_detail_from_clicks")

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing Update Conversion Pixel Detail **********"
    log.debug "\n"
  end
end
