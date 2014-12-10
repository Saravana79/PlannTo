class PopularVendorProductsUpdate
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :popular_vendor_products_update

  def self.perform(method_name)
    log = Logger.new 'log/popular_vendor_products_update.log'
    log.debug "********** Start Processing PopularVendorProductsUpdate **********"

    Advertisement.send(method_name)

    log.debug "********** End Processing PopularVendorProductsUpdate **********"
    log.debug "\n"
  end
end
