class ItemAdDetail < ActiveRecord::Base
  belongs_to :item

  def self.update_ad_details_for_items(log, batch_size=2000)
    query_to_get_price_and_vendor_ids = "select itemid as item_id,min(price) price,group_concat(distinct(site)) as vendor_id, i.itemtype_id as item_type, i.type as type, new_version_item_id from itemdetails id
             inner join items i on i.id = id.itemid where id.status in (1,3) and site in (9861,9882,9874,9880) group by itemid"
    # p_v_records = Item.find_by_sql(query_to_get_price_and_vendor_ids)

    log.debug "********** Started Updating ItemAdDetail for Items **********"
    # log.debug "********** Found #{p_v_records.count} items for update price and vendor_ids **********"
    log.debug "\n"

    page = 1
    begin
      items = Item.paginate_by_sql(query_to_get_price_and_vendor_ids, :page => page, :per_page => batch_size)

      items.each do |each_item|
        p "Processing ItemAdDetail for #{each_item.item_id}"
        new_version_id = each_item.new_version_item_id
        # old_version_id = Item.old_version_item_id(each_item.item_id) # TODO: we can update manually to improve performance

        related_item_ids = RelatedItem.where('item_id = ?', each_item.item_id).order('variance desc').limit(10).collect(&:related_item_id)
        related_item_ids = related_item_ids.map(&:inspect).join(',')

        item_ad_detail = ItemAdDetail.find_or_initialize_by_item_id(:item_id => each_item.item_id)
        # item_ad_detail.update_attributes(:new_version_id => new_version_id, :old_version_id => old_version_id, :related_item_ids => related_item_ids)
        item_ad_detail.update_attributes(:new_version_id => new_version_id, :related_item_ids => related_item_ids)
      end
      page += 1
    end while !items.empty?

    log.debug "********** Completed Updating ItemAdDetail for Items **********"
    log.debug "\n"

    update_clicks_and_impressions_for_ad_details(log, batch_size, Time.now)
  end

  def self.update_clicks_and_impressions_for_ad_details(log, batch_size=2000, time)

    log.debug "********** Updating clicks and impressions count **********"
    log.debug "\n"

    date_for_query = time.is_a?(Time) ? time.utc : time # converted to UTC

    date_for_query = date_for_query - 1.month

    impression_query = "select item_id, count(*) as impression_count from add_impressions where impression_time >= '#{date_for_query}' group by item_id"
    click_query = "select item_id,count(*) as click_count from clicks where timestamp >= '#{date_for_query}' group by item_id"
    order_query = "select item_id,count(*) as count from order_histories where order_date >= '#{date_for_query}' group by item_id"

    page = 1
    begin
      impressions = AddImpression.paginate_by_sql(impression_query, :page => page, :per_page => batch_size)

      impressions.each do |each_imp|
        p "Processing ItemAdDetail Impressions for #{each_imp.item_id}"
        item_ad_detail = ItemAdDetail.find_or_initialize_by_item_id(:item_id => each_imp.item_id)
        item_ad_detail.update_attributes(:impressions => each_imp.impression_count)
      end
      page += 1
    end while !impressions.empty?

    # @impressions = AddImpression.find_by_sql(impression_query)
    #
    # @impressions.each do |each_imp|
    #   item_ad_detail = ItemAdDetail.find_or_initialize_by_item_id(:item_id => each_imp.item_id)
    #   item_ad_detail.update_attributes(:impressions => each_imp.impression_count)
    # end

    @clicks = Click.find_by_sql(click_query)

    @clicks.each do |each_click|
      p "Processing ItemAdDetail Clicks for #{each_click.item_id}"
      item_ad_detail = ItemAdDetail.find_or_initialize_by_item_id(:item_id => each_click.item_id)
      item_ad_detail.update_attributes(:clicks => each_click.click_count)
    end

    @orders = OrderHistory.find_by_sql(order_query)

    @orders.each do |each_order|
      p "Processing ItemAdDetail Orders for #{each_order.item_id}"
      item_ad_detail = ItemAdDetail.find_or_initialize_by_item_id(:item_id => each_order.item_id)
      item_ad_detail.update_attributes(:orders => each_order.count)
    end

    update_ectr_for_item_ad_detail(log, batch_size)
  end

  def self.update_ectr_for_item_ad_detail(log, batch_size=2000)
    log.debug "********** Updating ectr **********"
    log.debug "\n"

    query_to_get_clicks_and_impressions = "select item_id, clicks, impressions, orders from item_ad_details where impressions > 100 order by impressions desc"

    page = 1
    begin
      items = ItemAdDetail.paginate_by_sql(query_to_get_clicks_and_impressions, :page => page, :per_page => batch_size)

      items.each do |each_item|
        p "Processing ItemAdDetail ectr for #{each_item.item_id}"
        clicks_count = each_item.clicks.to_f
        impressions_count = each_item.impressions.to_f
        orders_count = each_item.orders.to_f

        ectr = 0.0

        if (clicks_count != 0.0 && impressions_count != 0.0)
          ectr = (clicks_count / impressions_count) + (orders_count / clicks_count) rescue 0.0
        end


        item_ad_detail = ItemAdDetail.find_or_initialize_by_item_id(:item_id => each_item.item_id)
        item_ad_detail.update_attributes!(:ectr => ectr)

        # Redis items:"#{id}" update with impresssions, clicks and orders
        redis_key = "items:#{item_ad_detail.id}"
        redis_values = "impressions", item_ad_detail.impressions, "clicks", item_ad_detail.clicks, "orders", item_ad_detail.orders
        $redis_rtb.HMSET(redis_key, redis_values)
      end
      page += 1
    end while !items.empty?
  end

end
