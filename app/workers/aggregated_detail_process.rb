class AggregatedDetailProcess
  @queue = :aggregated_detail_process

  def self.perform(actual_time)
    log = Logger.new 'log/aggregated_detail_process.log'
    #begin
    log.debug "********** Start Processing aggregated detail **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time

    before_hour = now_time - 1.hour

    AggregatedDetail.update_aggregated_detail(now_time)

    if (before_hour.day != now_time.day)
      AggregatedDetail.update_aggregated_detail(before_hour)
    end

    #rescue Exception => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing aggregated detail **********"
    log.debug "\n"
  end
end
