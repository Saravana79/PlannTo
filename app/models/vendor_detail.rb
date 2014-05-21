class VendorDetail < ActiveRecord::Base
  belongs_to :item
  belongs_to :vendor, :foreign_key => "item_id"

 	def self.getdomain(url)
		host = URI.parse(url).host.downcase rescue ""
		domain = host.start_with?('www.') ? host[4..-1] : host	
		domain = domain.start_with?('offers.') ? domain[7..-1] : domain
		domain = domain.start_with?('smartphone.') ? domain[11..-1] : domain            	
  end

  # def self.get_vendor_detail_for_ad(item_detail)
  #   unless item_detail.blank?
  #     vendor_detail = ""
  #     vendor_detail = find_by_sql("SELECT name, imageurl, default_text FROM `vendor_details` WHERE (item_id = #{item_detail.site})").first
  #     return configatron.root_image_url + "vendor" + '/medium/' + vendor_detail.imageurl.to_s, vendor_detail.default_text, vendor_detail.name unless vendor_detail.blank?
  #   end
  #   return "", ""
  # end

  def self.get_vendor_ad_details(item_ids)
    vendor_details = {}
    details = find_by_sql("SELECT item_id, name as vendor_name, imageurl, default_text FROM `vendor_details` WHERE item_id in (#{item_ids.map(&:inspect).join(', ')})")

    details.map {|each_detail| vendor_details.merge!(each_detail.item_id => each_detail.attributes.merge('imageurl' => configatron.root_image_url + "vendor" + '/medium/' + each_detail.imageurl.to_s))}

    # Vendor.where("id in (?)", item_ids).map {|each_vendor| vendor_details.merge!(each_vendor.id => {:image_url => each_vendor.image_url, :default_text => each_vendor.default_text, :vendor_name => each_vendor.name})}
    vendor_details
  end
end
