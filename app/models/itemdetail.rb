class Itemdetail < ActiveRecord::Base

  has_one :vendor, :primary_key => "site", :foreign_key => "id"
  belongs_to :item

  def vendor_name
    return "" if vendor.nil?
    return vendor.name
  end

  def image_url
    return "" if vendor.nil?
    return vendor.imageurl
  end
  
  def self.display_item_details(item)
    if item.status ==1 && !item.IsError?
    return true
    else
    return false
    end
  end
  
   def self.display_shipping_detail(item)
    unless item.shipping.blank?
      unit = ""
      if item.shippingunit == 1
        unit = "hours"
      elsif item.shippingunit == 2
        unit = "Business days"
      elsif item.shippingunit == 3
        unit = "Months"
      elsif item.shippingunit == 4
        unit = "Years"
      end
      "#{item.shipping} #{unit}"
    else
      "N/A"
    end

  end

  def self.display_price_detail(item)
    if(!item.cashback.nil? && item.cashback != 0.0)
      item.price == 0.0 ? "N/A" :  Itemdetail.number_to_indian_currency(item.price - item.cashback).to_s
    else
    item.price == 0.0 ? "N/A" :  Itemdetail.number_to_indian_currency(item.price).to_s
    end

  end
  def self.number_to_indian_currency(number)
    if number
      string = number.to_s
      number = string.to_s.gsub(/(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?/, "\\1,")
    end
    "Rs #{number}"
  end
end
