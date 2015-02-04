class PopularVendorFlipkartProductUpdate
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :popular_vendor_flipkart_product_update

  def self.perform
    log = Logger.new 'log/popular_vendor_products_update.log'
    log.debug "********** Start Processing PopularVendorProductsUpdate **********"

    Advertisement.update_include_exclude_products_from_vendor_flipkart()

    log.debug "********** End Processing PopularVendorProductsUpdate **********"
    log.debug "\n"
  end
end
