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
        new_version_id = each_item.new_version_item_id
        # old_version_id = Item.old_version_item_id(each_item.item_id) # TODO: we can update manually to improve performance

        related_item_ids = RelatedItem.where('item_id = ?', each_item.item_id).limit(10).collect(&:related_item_id)
        related_item_ids = related_item_ids.map(&:inspect).join(',')

        item_ad_detail = ItemAdDetail.find_or_initialize_by_item_id(:item_id => each_item.item_id)
        item_ad_detail.update_attributes(:new_version_id => new_version_id, :old_version_id => old_version_id, :related_item_ids => related_item_ids)
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

    impression_query = "select item_id, count(*) as impression_count from add_impressions where date(impression_time) >= date('#{date_for_query}') group by item_id"
    click_query = "select item_id,count(*) as click_count from clicks where date(timestamp) >= date('#{date_for_query}') group by item_id"

    @impressions = AddImpression.find_by_sql(impression_query)

    @impressions.each do |each_imp|
      item_ad_detail = ItemAdDetail.find_or_initialize_by_item_id(:item_id => each_imp.item_id)
      item_ad_detail.update_attributes(:impressions => each_imp.impression_count)
    end

    @clicks = Click.find_by_sql(click_query)

    @clicks.each do |each_click|
      item_ad_detail = ItemAdDetail.find_or_initialize_by_item_id(:item_id => each_click.item_id)
      item_ad_detail.update_attributes(:clicks => each_click.click_count)
    end

    update_ectr_for_item_ad_detail(log, batch_size)
  end

  def self.update_ectr_for_item_ad_detail(log, batch_size=2000)
    log.debug "********** Updating ectr **********"
    log.debug "\n"

    query_to_get_clicks_and_impressions = "select item_id, clicks, impressions from item_ad_details"

    page = 1
    begin
      items = ItemAdDetail.paginate_by_sql(query_to_get_clicks_and_impressions, :page => page, :per_page => batch_size)

      items.each do |each_item|
        clicks_count = each_item.clicks.to_f
        impressions_count = each_item.impressions.to_f

        ectr = 0.0

        if (clicks_count != 0.0 && impressions_count != 0.0)
          ectr = (clicks_count.to_f / impressions_count.to_f) rescue 0.0
        end


        item_ad_detail = ItemAdDetail.find_or_initialize_by_item_id(:item_id => each_item.item_id)
        item_ad_detail.update_attributes(:ectr => ectr)
      end
      page += 1
    end while !items.empty?
  end

end
