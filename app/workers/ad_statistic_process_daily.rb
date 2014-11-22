class AdStatisticProcessDaily
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :ad_statistic_process

  def self.perform(method_name)
    log = Logger.new 'log/clean_up_redis_keys.log'
    log.debug "********** Start Processing AdStatisticProcessDaily **********"

    AdStatistic.send(method_name)

    log.debug "********** End Processing AdStatisticProcessDaily **********"
    log.debug "\n"
  end
end
