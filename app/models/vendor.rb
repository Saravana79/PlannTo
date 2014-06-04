class Vendor < Item
  has_many :vendor_details, :foreign_key => :item_id
  has_many :hotel_vendor_details
 
 def self.get_item_object(item)
    item = item.vendor
 end

  def self.get_vendor_ids_by_publisher(publisher, vendor_ids)
    pub_vendor_ids = publisher.vendor_ids.split(',') unless publisher.blank?
    if !pub_vendor_ids.blank?
      pub_vendor_ids = pub_vendor_ids.map(&:to_i)
      suffix_order = vendor_ids - pub_vendor_ids
      vendor_ids = pub_vendor_ids + suffix_order
    end
    return vendor_ids
  end

end