class AggregatedDetailProcess
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :aggregated_detail_process

  def self.perform(actual_time, only_ad="true")
    log = Logger.new 'log/aggregated_detail_process.log'
    #begin
    log.debug "********** Start Processing aggregated detail **********"
    log.debug "********** Actual Time to Start #{actual_time.to_time.strftime('%b %d,%Y %r')} **********"

    now_time = actual_time.to_time
    now_time = now_time.utc

    before_hour = now_time - 1.hour
    before_3_hour = now_time - 3.hour
    before_5_hour = now_time - 5.hour

    if only_ad == "false"
      #from mongo report
      # AggregatedDetail.update_aggregated_details_from_mongo_reports(now_time, 'publisher', "Publisher")
      #
      # if (before_hour.day != now_time.day || before_3_hour.day != now_time.day || before_5_hour.day != now_time.day)
      #   AggregatedDetail.update_aggregated_details_from_mongo_reports(now_time.yesterday, 'publisher', "Publisher")
      # end

      #from Aggregated Impression
      AggregatedDetail.update_aggregated_details_from_aggregated_impression(now_time, 'publisher', "Publisher")

      if (before_hour.day != now_time.day || before_3_hour.day != now_time.day || before_5_hour.day != now_time.day)
        AggregatedDetail.update_aggregated_details_from_aggregated_impression(now_time.yesterday, 'publisher', "Publisher")
      end
    end

    #mongo report
    # AggregatedDetail.update_aggregated_details_from_mongo_reports(now_time, 'advertisement', "Advertisement")
    #
    # if (before_hour.day != now_time.day || before_3_hour.day != now_time.day || before_5_hour.day != now_time.day)
    #   AggregatedDetail.update_aggregated_details_from_mongo_reports(now_time.yesterday, 'advertisement', "Advertisement")
    # end

    #from Aggregated Impression
    AggregatedDetail.update_aggregated_details_from_aggregated_impression(now_time, 'advertisement', "Advertisement")

    if (before_hour.day != now_time.day || before_3_hour.day != now_time.day || before_5_hour.day != now_time.day)
      AggregatedDetail.update_aggregated_details_from_aggregated_impression(now_time.yesterday, 'advertisement', "Advertisement")
    end

    #rescue => e
    #  log.debug "Have some problem while executing calculate ecpm, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "Advertisement Process").deliver
    #end
    log.debug "********** End Processing aggregated detail **********"
    log.debug "\n"
  end
end
