class SidAdDetail < ActiveRecord::Base
  def self.update_ad_details_for_sid(log, batch_size=2000)
    date_for_query = Time.now.utc - 2.month
    query_to_get_add_impressions = "select sid FROM add_impressions1 where impression_time >= '2014-07-20' and impression_time >= '#{date_for_query}' and sid is not null group by sid"
    # p_v_records = Item.find_by_sql(query_to_get_price_and_vendor_ids)

    log.debug "********** Started Updating SidAdDetail for add impressions **********"
    log.debug "\n"

    page = 1
    begin
      add_impressions = AddImpression.paginate_by_sql(query_to_get_add_impressions, :page => page, :per_page => batch_size)

      add_impressions.each do |each_impression|
        s_id = each_impression.sid
        sid_ad_detail = SidAdDetail.find_or_initialize_by_sid(:sid => s_id)
        sid_ad_detail.save! if sid_ad_detail.new_record?
        p "Initialize sid: #{s_id}"
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
    date_for_query = date_for_query.strftime("%Y-%m-%d")
    current_date = Time.now.strftime("%Y-%m-%d")

    # select sid, count(*) as impression_count from add_impressions where impression_time >= "2014-07-20 00:00:00" and impression_time >= "2014-06-22 00:00:00" and sid is not null group by sid
    impression_query = "select sid, count(*) as impression_count, avg(winning_price) as avg_winning_price from add_impressions1 where impression_time >= '#{date_for_query}' and impression_time <= '#{current_date}' and sid is not null group by sid having impression_count > 500"
    click_query = "select sid,count(*) as click_count from clicks where timestamp >= '#{date_for_query}' group by sid"
    order_query = "select sid,count(*) as count from add_impressions1 ai inner join  (select UNHEX(CONCAT(LEFT(impression_id, 8), MID(impression_id, 10, 4), MID(impression_id, 15, 4), MID(impression_id, 20, 4), RIGHT(impression_id, 12))) as id from order_histories  where  impression_id is not null) oh on oh.id = ai.id
where ai.impression_time >= '#{date_for_query}' group by sid order by count(*) desc"

    page = 1
    begin
      impressions = AddImpression.paginate_by_sql(impression_query, :page => page, :per_page => batch_size)

      impressions.each do |each_imp|
        begin
          sid_ad_detail = SidAdDetail.find_or_initialize_by_sid(:sid => each_imp.sid)
          sid_ad_detail.update_attributes(:impressions => each_imp.impression_count, :avg_winning_price => each_imp.avg_winning_price)

          if sid_ad_detail.sample_url.blank?
            sid_ad_detail_sid = sid_ad_detail.sid
            p "Updating impression for #{sid_ad_detail_sid}"
            sid_key = "spottags:#{sid_ad_detail_sid}"
            sid_val = $redis_rtb.hget(sid_key, "sid_details")
            unless sid_val.blank?
              begin
                sid_hash = JSON.parse(sid_val)
              rescue JSON::ParserError => e
                sid_hash = JSON.parse(eval(sid_val))
              end

              host = URI.parse(sid_hash["url"]).host.downcase rescue ""
              updated_host = host.start_with?('www.') ? host[4..-1] : host
              sid_ad_detail.update_attributes(:sample_url => sid_hash["url"], :domain => updated_host, :size => "#{sid_hash["imp"][0]["banner"]["w"]}x#{sid_hash["imp"][0]["banner"]["h"]}", :position => sid_hash["imp"][0]["banner"]["pos"])
            end
          end
        rescue Exception => e
          p "skipped this spottag"
        end
      end
      page += 1
    end while !impressions.empty?

    # @impressions = AddImpression.find_by_sql(impression_query)
    #
    # @impressions.each do |each_imp|
    #   sid_ad_detail = SidAdDetail.find_or_initialize_by_sid(:sid => each_imp.sid)
    #   sid_ad_detail.update_attributes(:impressions => each_imp.impression_count)
    #
    #   if sid_ad_detail.sample_url.blank?
    #     sid_key = "spottags:#{sid_ad_detail.sid}"
    #     sid_val = $redis_rtb.get(sid_key)
    #     unless sid_val.blank?
    #       sid_hash = JSON.parse(eval(sid_val))
    #       host = URI.parse(sid_hash["url"]).host.downcase
    #       updated_host = host.start_with?('www.') ? host[4..-1] : host
    #       sid_ad_detail.update_attributes(:sample_url => sid_hash["url"], :domain => updated_host, :size => "#{sid_hash["imp"][0]["banner"]["w"]}x#{sid_hash["imp"][0]["banner"]["h"]}", :position => sid_hash["imp"][0]["banner"]["pos"])
    #     end
    #   end
    # end

    p "Started Clicks Update"

    page = 1
    begin
      clicks = Click.paginate_by_sql(click_query, :page => page, :per_page => batch_size)

      clicks.each do |each_click|
        each_click_sid = each_click.sid
        p "Updating Clicks for #{each_click_sid}"
        sid_ad_detail = SidAdDetail.find_or_initialize_by_sid(:sid => each_click_sid)
        sid_ad_detail.update_attributes(:clicks => each_click.click_count)
      end
      page += 1
    end while !clicks.empty?

    @orders = OrderHistory.find_by_sql(order_query)

    @orders.each do |each_order|
      each_order_sid = each_order.sid
      p "Updating Orders for #{each_order_sid}"
      sid_ad_detail = SidAdDetail.find_or_initialize_by_sid(:sid => each_order_sid)
      sid_ad_detail.update_attributes(:orders => each_order.count)
    end

    update_ectr_for_sid_ad_details(log, batch_size)
  end

  def self.update_ectr_for_sid_ad_details(log, batch_size=2000)
    log.debug "********** Updating ectr **********"
    log.debug "\n"

    query_to_get_clicks_and_impressions = "select sid, clicks, impressions, orders from sid_ad_details  where impressions > 500 order by impressions desc"

    page = 1
    begin
      sid_ad_details = SidAdDetail.paginate_by_sql(query_to_get_clicks_and_impressions, :page => page, :per_page => batch_size)

      page += 1
      sid_ad_details.each do |each_sid_ad_detail|
        clicks_count = each_sid_ad_detail.clicks.to_f
        impressions_count = each_sid_ad_detail.impressions.to_f
        orders_count = each_sid_ad_detail.orders.to_f

        ectr = 0.0

        if (clicks_count != 0.0 && impressions_count != 0.0)
          ectr = (clicks_count / impressions_count) + (orders_count / clicks_count) rescue 0.0
        end

        each_sid_ad_detail_sid = each_sid_ad_detail.sid
        p "Updating ectr for #{each_sid_ad_detail_sid}"
        sid_ad_detail = SidAdDetail.find_or_initialize_by_sid(:sid => each_sid_ad_detail_sid)
        sid_ad_detail.update_attributes!(:ectr => ectr)

        # Redis sid:XXX update with impresssions, clicks and orders #TODO: remove permanatly later
        # redis_key = "sid:#{sid_ad_detail.sid}"
        # redis_values = "impressions", sid_ad_detail.impressions, "clicks", sid_ad_detail.clicks, "orders", sid_ad_detail.orders
        # $redis_rtb.HMSET(redis_key, redis_values)

        #update spottags with ectr
        if impressions_count > 500
          spottag_key = "spottags:#{sid_ad_detail.sid}"
          p "spottag key: #{spottag_key}"
          ectr_val = ectr * 1000

          if ectr_val >= 10
            final_ectr = 1.25
          elsif ectr_val >= 6 && ectr_val < 10
            final_ectr = 1.1
          elsif ectr_val >= 3 && ectr_val < 6
            final_ectr = 0.85
          elsif ectr_val >= 1 && ectr_val < 3
            final_ectr = 0.70
          elsif ectr_val < 1
            final_ectr = 0.2
          end
          $redis_rtb.HMSET(spottag_key, "ectr", final_ectr)
        end
      end
    end while !sid_ad_details.empty?
  end
end
