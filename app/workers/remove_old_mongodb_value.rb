class RemoveOldMongodbValue
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :remove_old_mongodb_values

  def self.perform(method_name)
    log = Logger.new 'log/remove_old_mongodb_values.log'

    AdImpression.send(method_name)
  end
end
