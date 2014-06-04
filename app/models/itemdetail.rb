class Itemdetail < ActiveRecord::Base

  has_one :vendor, :primary_key => "site", :foreign_key => "id"
  belongs_to :item, :foreign_key => "itemid"

  def self.get_item_details(item_id, vendor_ids)
    item_id = sanitize(item_id)
    # vendor_id = sanitize(vendor_id)
    find_by_sql("SELECT itemdetails.*, items.imageurl, items.type FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE items.id = #{item_id}
                 and itemdetails.isError = 0 and site in (#{vendor_ids.map(&:inspect).join(', ')}) ORDER BY itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0
                 else itemdetails.cashback end) asc")
  end

  def self.get_item_details_by_item_ids(item_ids, vendor_ids)
    status_condition = vendor_ids.count > 1 ? " and itemdetails.status in (1,3,2)" : ""
    # vendor_id = sanitize(vendor_id)

    find_by_sql("SELECT itemdetails.*, items.imageurl, items.type FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE items.id in (#{item_ids.map(&:inspect).join(', ')})
                 and itemdetails.isError =0 #{status_condition} and site in (#{vendor_ids.blank? ? "''" : vendor_ids.map(&:inspect).join(', ')}) ORDER BY field(items.id, #{item_ids.map(&:inspect).join(', ')}), itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else
                 itemdetails.cashback end) asc")
  end

  def self.get_item_details_by_item_ids_count(item_ids, vendor_ids, items, publisher, status, activate_tab)
    @item_details = []
    if item_ids.count > 1
      @item_details = Itemdetail.get_item_details_by_item_ids(item_ids, vendor_ids).group_by { |each_rec| each_rec.itemid }
    elsif item_ids.count == 1
      items = Item.get_related_items_if_one_item(items, @publisher, status) if (activate_tab && items.count == 1)
      @item_details = Itemdetail.get_item_details_by_item_ids(item_ids, vendor_ids).group_by { |each_rec| each_rec.itemid }
      # @item_details = Itemdetail.get_item_details(item_ids.first, vendor_ids).group_by { |each_rec| each_rec.itemid }
    end

    @item_details = @item_details.blank? ? [] : Itemdetail.get_sort_by_vendor(@item_details, vendor_ids).flatten.uniq(&:url)
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

  def self.get_sort_by_vendor(item_details, vendor_ids)
    exp_result = {}
    return_val = []

    item_details.keys.each do |each_key|
      splt_item_details = item_details[each_key]
      exp_result[each_key] = splt_item_details.group_by {|splt_each_item| splt_each_item.site.to_i}
    end

    item_keys = exp_result.keys
    max_count = exp_result.map {|_, s| s.map {|_, x| x.count}}.flatten.max

    vendor_orders = vendor_ids

    [*0...max_count].each do |each_val|
      item_keys.each do |each_item|
        vendor_orders.each do |each_vendor|
          unless exp_result[each_item.to_i][each_vendor].blank?
            item_detail = exp_result[each_item][each_vendor][each_val]
            return_val << item_detail unless item_detail.blank?
          end
        end
      end
    end

    return_val
  end

  def self.get_where_to_buy_items(publisher, items, show_price, status, url, user, remote_ip, itemsaccess, url_params, plan_to_temp_user_id)
    country = ""
    tempitems = []
    if (!publisher.nil? && publisher.id == 9 && country != "India")
      where_to_buy_items = []
      item = items[0]
      itemsaccess = "othercountry"
    elsif show_price != "false"
        where_to_buy_items, tempitems, item = Item.process_and_get_where_to_buy_items(items, publisher, status)
        main_item = item
        items = items - tempitems

        # for activate_tab users
        if (items.blank? && where_to_buy_items.blank?)
          item = main_item
          items = Item.where(:id => item.new_version_item_id)
          where_to_buy_items, tempitems, item = Item.process_and_get_where_to_buy_items(items, publisher, status)

          items = items - tempitems

          if (items.blank? && where_to_buy_items.blank?)
            item_ad_detail = main_item.item_ad_detail
            unless item_ad_detail.blank?
              items = Item.where(:id => item_ad_detail.old_version_id)
              where_to_buy_items, tempitems, item = Item.process_and_get_where_to_buy_items(items, publisher, status)
              items = items - tempitems
            end
          end
        end

        if (where_to_buy_items.empty?)
          itemsaccess = "emptyitems"
        end

        AddImpression.add_impression_to_resque("pricecomparision", item.id, url, user, remote_ip, nil, itemsaccess, url_params,
                                               plan_to_temp_user_id, nil)
      else
        where_to_buy_items = []
        item, best_deals = ArticleContent.get_best_deals(items.map(&:id).join(",").split(","), url, url_params)
        p 4444444
        p item
        p best_deals
        itemsaccess = "offers"
      end

    return where_to_buy_items, item, best_deals
  end
end
