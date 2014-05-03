class Itemdetail < ActiveRecord::Base

  has_one :vendor, :primary_key => "site", :foreign_key => "id"
  belongs_to :item, :foreign_key => "itemid"

  def self.get_item_details(item_id, vendor_id)
    item_id = sanitize(item_id)
    vendor_id = sanitize(vendor_id)
    find_by_sql("SELECT itemdetails.*, items.imageurl, items.type FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE (items.id = #{item_id}
                 and itemdetails.isError = 0 and site = #{vendor_id}) ORDER BY itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0
                 else itemdetails.cashback end) asc")
  end

  def self.get_item_details_by_item_ids(item_ids, vendor_id)
    vendor_id = sanitize(vendor_id)

    find_by_sql("SELECT itemdetails.*, items.imageurl, items.type FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE (items.id in (#{item_ids.map(&:inspect).join(', ')})
                 and itemdetails.isError =0 and site = #{vendor_id}) ORDER BY itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else
                 itemdetails.cashback end) asc")
  end

  def vendor_name
    return "" if vendor.nil?
    return vendor.name
  end

  def image_url
    return "" if vendor.nil?
    return vendor.imageurl
  end
  
  def self.display_item_details(item)
if ((item.status ==1 || item.status ==3)  && !item.IsError?)
    return true
    else
    return false
    end
  end
  

  def self.display_availability_detail(item)

    if(item.status  == 1)
       "Available"
    elsif(item.status  == 2)
      "Out of Stock"
    elsif(item.status  == 3) 
      "Pre-Order"
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
      if item.status == 3
        "[Pre-Order]"
      else        
        "N/A"
      end
    end

  end

  def self.display_price_detail(item)
    if(!item.cashback.nil? && item.cashback != 0.0)
      item.price == 0.0 ? "N/A" :  Itemdetail.number_to_indian_currency((item.price - item.cashback).to_f.round(2)).to_s
    else
    item.price == 0.0 ? "N/A" :  Itemdetail.number_to_indian_currency(item.price.to_f.round(2)).to_s
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
