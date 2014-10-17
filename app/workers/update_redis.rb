class UpdateRedis
  extend HerokuResqueAutoScale
  @queue = :update_redis

  def self.perform(redis_key, *redis_values)
    update_for = redis_key.split(":")[0]
    update_for = "contents" if update_for == "url"
    log = Logger.new 'log/update_redis.log'
    log.debug "********** #{update_for} - Update Redis Process Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    log.debug "Hash Key => #{redis_key}"
    log.debug "Hash value => #{redis_values}"
    #begin
    $redis_rtb.HMSET(redis_key, redis_values)
    #rescue Exception => e
    #  log.debug "Have some problem while executing redis update for #{updated_for}, please find the error below"
    #  log.debug e
    #  NotificationMailer.resque_process_failure(e, e.backtrace, log, "#{update_for} - Update Redis Process").deliver
    #end

    log.debug "********** #{update_for} - Update Redis Process Completed at - #{Time.zone.now.strftime('%b %d,%Y %r')} **********"
    log.debug "\n"
  end
end
