class PopularVendorJungleeFashionProductUpdate
  extend HerokuResqueAutoScale if Rails.env.production?
  extend Resque::Plugins::Retry
  @queue = :popular_vendor_junglee_fashion_product_update

  def self.perform
    log = Logger.new 'log/popular_vendor_junglee_fashion_product_update.log'
    log.debug "********** Start Processing PopularVendorJungleeFashionProductUpdate **********"

    Advertisement.update_fashion_item_details_from_junglee()

    log.debug "********** End Processing PopularVendorJungleeFashionProductUpdate **********"
    log.debug "\n"
  end
end
