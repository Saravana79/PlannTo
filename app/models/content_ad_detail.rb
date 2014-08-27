class ContentAdDetail < ActiveRecord::Base

  def self.update_ad_details_for_contents(log, batch_size=2000)
    query_to_get_article_contents = "SELECT a_c.* FROM view_article_contents a_c inner join add_impressions i on i.hosted_site_url= a_c.url WHERE a_c.type IN ('ArticleContent') group by url"
    # p_v_records = Item.find_by_sql(query_to_get_price_and_vendor_ids)

    log.debug "********** Started Updating ContentAdDetail for Content **********"
    # log.debug "********** Found #{p_v_records.count} items for update price and vendor_ids **********"
    log.debug "\n"

    page = 1
    begin
      contents = ArticleContent.paginate_by_sql(query_to_get_article_contents, :page => page, :per_page => batch_size)

      contents.each do |each_content|
        content_ad_detail = ContentAdDetail.find_or_initialize_by_url(:url => each_content.url)
        content_ad_detail.save!
      end
      page += 1
    end while !contents.empty?

    log.debug "********** Completed Updating ContentAdDetail for Contents **********"
    log.debug "\n"

    update_clicks_and_impressions_for_content_ad_details(log, batch_size, Time.now)
  end

  def self.update_clicks_and_impressions_for_content_ad_details(log, batch_size=2000, time)

    log.debug "********** Updating clicks and impressions count **********"
    log.debug "\n"

    date_for_query = time.is_a?(Time) ? time.utc : time # converted to UTC

    date_for_query = date_for_query - 1.month

    impression_query = "select hosted_site_url as url, count(*) as impression_count from add_impressions where impression_time >= '#{date_for_query}' group by hosted_site_url"
    click_query = "select hosted_site_url as url,count(*) as click_count from clicks where timestamp >= '#{date_for_query}' group by hosted_site_url"
    order_query = "select hosted_site_url as url,count(*) as count from add_impressions ai inner join  (select UNHEX(CONCAT(LEFT(impression_id, 8), MID(impression_id, 10, 4), MID(impression_id, 15, 4), MID(impression_id, 20, 4), RIGHT(impression_id, 12))) as id from order_histories  where  impression_id is not null) oh on oh.id = ai.id
where ai.impression_time >= '#{date_for_query}' group by hosted_site_url order by count(*) desc"

    page = 1
    begin
      impressions = AddImpression.paginate_by_sql(impression_query, :page => page, :per_page => batch_size)

      impressions.each do |each_imp|
        content_ad_detail = ContentAdDetail.find_or_initialize_by_url(:url => each_imp.url)
        content_ad_detail.update_attributes(:impressions => each_imp.impression_count)
      end
      page += 1
    end while !impressions.empty?

    # @impressions = AddImpression.find_by_sql(impression_query)
    #
    # @impressions.each do |each_imp|
    #   content_ad_detail = ContentAdDetail.find_or_initialize_by_url(:url => each_imp.url)
    #   content_ad_detail.update_attributes(:impressions => each_imp.impression_count)
    # end

    @clicks = Click.find_by_sql(click_query)

    @clicks.each do |each_click|
      content_ad_detail = ContentAdDetail.find_or_initialize_by_url(:url => each_click.url)
      content_ad_detail.update_attributes(:clicks => each_click.click_count)
    end

    @orders = OrderHistory.find_by_sql(order_query)

    @orders.each do |each_order|
      content_ad_detail = ContentAdDetail.find_or_initialize_by_url(:url => each_order.url)
      content_ad_detail.update_attributes(:orders => each_order.count)
    end

    update_ectr_for_content_ad_detail(log, batch_size)
  end

  def self.update_ectr_for_content_ad_detail(log, batch_size=2000)
    log.debug "********** Updating ectr **********"
    log.debug "\n"

    query_to_get_clicks_and_impressions = "select url, clicks, impressions from content_ad_details  where impressions > 100 order by impressions desc"

    page = 1
    begin
      content_ad_details = ContentAdDetail.paginate_by_sql(query_to_get_clicks_and_impressions, :page => page, :per_page => batch_size)

      page += 1
      content_ad_details.each do |each_content|
        clicks_count = each_content.clicks.to_f
        impressions_count = each_content.impressions.to_f

        ectr = 0.0

        if (clicks_count != 0.0 && impressions_count != 0.0)
          ectr = (clicks_count.to_f / impressions_count.to_f) rescue 0.0
        end


        content_ad_detail = ContentAdDetail.find_or_initialize_by_url(:url => each_content.url)
        content_ad_detail.update_attributes!(:ectr => ectr)

        # Redis url:XXX update with impresssions, clicks and orders
        redis_key = "url:#{content_ad_detail.url}"
        redis_values = "impressions", content_ad_detail.impressions, "clicks", content_ad_detail.clicks, "orders", content_ad_detail.orders
        $redis_rtb.HMSET(redis_key, redis_values)
      end
    end while !content_ad_details.empty?
  end

end
