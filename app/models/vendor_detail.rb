class VendorDetail < ActiveRecord::Base
  belongs_to :item
  belongs_to :vendor, :foreign_key => "item_id"

 	def self.getdomain(url)
		host = URI.parse(url).host.downcase rescue ""
		domain = host.start_with?('www.') ? host[4..-1] : host	
		domain = domain.start_with?('offers.') ? domain[7..-1] : domain
		domain = domain.start_with?('smartphone.') ? domain[11..-1] : domain            	
  end

  def self.get_vendor_detail_for_ad(item_detail)
    unless item_detail.blank?
      vendor_detail = ""
      vendor = item_detail.vendor
      vendor_id = vendor.blank? ? "" : vendor.id
      vendor_detail = find_by_sql("SELECT imageurl, default_text FROM `vendor_details` WHERE (item_id = #{vendor_id})").first unless vendor_id.blank?
      return configatron.root_image_url + "vendor" + '/medium/' + vendor_detail.imageurl.to_s, vendor_detail.default_text unless vendor_detail.blank?
    end
    return "", ""
  end
end
