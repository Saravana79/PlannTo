class RemoveOldMongodbValue
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :remove_old_mongodb_values

  def self.perform(method_name)
    log = Logger.new 'log/remove_old_mongodb_values.log'

    PUserDetail.remove_old_records()

    AdImpression.send(method_name)
  end
end
