class SidAdDetail < ActiveRecord::Base
  def self.update_ad_details_for_sid(log, batch_size=2000)
    query_to_get_add_impressions = "select sid FROM add_impressions where sid is not null  group by sid"
    # p_v_records = Item.find_by_sql(query_to_get_price_and_vendor_ids)

    log.debug "********** Started Updating SidAdDetail for add impressions **********"
    log.debug "\n"

    page = 1
    begin
      add_impressions = AddImpression.paginate_by_sql(query_to_get_add_impressions, :page => page, :per_page => batch_size)

      add_impressions.each do |each_impression|
        sid_ad_detail = SidAdDetail.find_or_initialize_by_sid(:sid => each_impression.sid)
        sid_ad_detail.save!
      end
      page += 1
    end while !add_impressions.empty?

    log.debug "********** Completed Updating SidAdDetail for AddImpression **********"
    log.debug "\n"

    update_clicks_and_impressions_for_sid_ad_details(log, batch_size, Time.now)
  end

  def self.update_clicks_and_impressions_for_sid_ad_details(log, batch_size=2000, time)

    log.debug "********** Updating clicks and impressions count **********"
    log.debug "\n"

    date_for_query = time.is_a?(Time) ? time.utc : time # converted to UTC

    date_for_query = date_for_query - 1.month

    impression_query = "select sid, count(*) as impression_count from add_impressions where date(impression_time) >= date('#{date_for_query}') group by sid"
    click_query = "select sid,count(*) as click_count from clicks where date(timestamp) >= date('#{date_for_query}') group by sid"
    order_query = "select sid,count(*) as count from add_impressions ai inner join  (select UNHEX(CONCAT(LEFT(impression_id, 8), MID(impression_id, 10, 4), MID(impression_id, 15, 4), MID(impression_id, 20, 4), RIGHT(impression_id, 12))) as id from order_histories  where  impression_id is not null) oh on oh.id = ai.id
where date(ai.impression_time) >= date('#{date_for_query}') group by sid order by count(*) desc"

    @impressions = AddImpression.find_by_sql(impression_query)

    @impressions.each do |each_imp|
      sid_ad_detail = SidAdDetail.find_or_initialize_by_sid(:sid => each_imp.sid)
      sid_ad_detail.update_attributes(:impressions => each_imp.impression_count)

      sid_key = "spottags:#{sid_ad_detail.sid}"
      sid_val = $redis_rtb.get(sid_key)
      unless sid_val.blank?
        sid_hash = JSON.parse(eval(sid_val))
        host = URI.parse(sid_hash["url"]).host.downcase
        updated_host = host.start_with?('www.') ? host[4..-1] : host
        sid_ad_detail.update_attributes(:sample_url => sid_hash["url"], :domain => updated_host, :size => "#{a["imp"][0]["banner"]["w"]}x#{a["imp"][0]["banner"]["h"]}", :position => a["imp"][0]["banner"]["pos"])
      end
    end

    @clicks = Click.find_by_sql(click_query)

    @clicks.each do |each_click|
      sid_ad_detail = SidAdDetail.find_or_initialize_by_sid(:sid => each_click.sid)
      sid_ad_detail.update_attributes(:clicks => each_click.click_count)
    end

    @orders = OrderHistory.find_by_sql(order_query)

    @orders.each do |each_order|
      sid_ad_detail = SidAdDetail.find_or_initialize_by_sid(:sid => each_order.sid)
      sid_ad_detail.update_attributes(:orders => each_order.count)
    end

    update_ectr_for_sid_ad_details(log, batch_size)
  end

  def self.update_ectr_for_sid_ad_details(log, batch_size=2000)
    log.debug "********** Updating ectr **********"
    log.debug "\n"

    query_to_get_clicks_and_impressions = "select sid, clicks, impressions, orders from sid_ad_details"

    page = 1
    begin
      sid_ad_details = AddImpression.paginate_by_sql(query_to_get_clicks_and_impressions, :page => page, :per_page => batch_size)

      page += 1
      sid_ad_details.each do |each_sid_ad_detail|
        clicks_count = each_sid_ad_detail.clicks.to_f
        impressions_count = each_sid_ad_detail.impressions.to_f
        orders_count = each_sid_ad_detail.orders.to_f

        ectr = 0.0

        if (clicks_count != 0.0 && impressions_count != 0.0)
          ectr = (clicks_count / impressions_count) + (orders_count / clicks_count) rescue 0.0
        end


        sid_ad_detail = SidAdDetail.find_or_initialize_by_sid(:sid => each_sid_ad_detail.sid)
        sid_ad_detail.update_attributes!(:ectr => ectr)

        # Redis sid:XXX update with impresssions, clicks and orders
        redis_key = "sid:#{sid_ad_detail.sid}"
        redis_values = "impressions", sid_ad_detail.impressions, "clicks", sid_ad_detail.clicks, "orders", sid_ad_detail.orders
        $redis_rtb.HMSET(redis_key, redis_values)
      end
    end while !sid_ad_details.empty?
  end
end
