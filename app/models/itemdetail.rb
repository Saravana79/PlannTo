class Itemdetail < ActiveRecord::Base

  has_one :vendor, :primary_key => "site", :foreign_key => "id"

  def vendor_name
    return "" if vendor.nil?
    return vendor.name
  end

  def image_url
    return "" if vendor.nil?
    return vendor.imageurl
  end
end
