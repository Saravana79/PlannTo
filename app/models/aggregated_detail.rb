class AggregatedDetail < ActiveRecord::Base
  belongs_to :entity, :polymorphic => true

  def self.update_aggregated_detail(time, entity_type, batch_size=1000)
    time = time.localtime
    if $redis.get("update_aggregated_detail_is_running").to_i == 0
      $redis.set("update_aggregated_detail_is_running", 1)
      $redis.expire("update_aggregated_detail_is_running", 30.minutes)

      entity_field = entity_type + "_id"
      # time = time.is_a?(Time) ? time.utc : time # converted to UTC

      impression_date_condition = "impression_time > '#{time.beginning_of_day.utc.strftime('%F %T')}' and impression_time < '#{time.end_of_day.utc.strftime('%F %T')}'"
      click_date_condition = "timestamp > '#{time.beginning_of_day.utc.strftime('%F %T')}' and timestamp < '#{time.end_of_day.utc.strftime('%F %T')}'"

      if entity_type == "publisher"
        impression_query = "select publisher_id as entity_id,count(*) as impression_count, sum(winning_price)/1000000 as winning_price from add_impressions1 where #{impression_date_condition} group by publisher_id"
        click_query = "select publisher_id as entity_id,count(*) as click_count from clicks where #{click_date_condition} group by publisher_id"
      elsif entity_type == "advertisement"
        impression_query = "select advertisement_id as entity_id,count(*) as impression_count, sum(winning_price)/1000000 as winning_price, a.commission from add_impressions1 ai inner join advertisements a on ai.advertisement_id = a.id where #{impression_date_condition} and ai.advertisement_type='advertisement' group by advertisement_id"
        click_query = "select advertisement_id as entity_id,count(*) as click_count from clicks where #{click_date_condition} and advertisement_id is NOT NULL group by advertisement_id"
      end

      page = 1
      begin
        impressions = AddImpression.paginate_by_sql(impression_query, :page => page, :per_page => batch_size)

        impressions.each do |each_imp|
          winning_price = each_imp.winning_price
          if entity_type == "advertisement"
            commission = each_imp.commission.blank? ? 1 : each_imp.commission.to_f
            winning_price = winning_price.to_f + (winning_price.to_f * (commission/100))
          end
          aggregated_detail = AggregatedDetail.find_or_initialize_by_entity_id_and_date_and_entity_type(:entity_id => each_imp.entity_id, :date => time.to_date, :entity_type => entity_type)
          aggregated_detail.update_attributes(:impressions_count => each_imp.impression_count, :winning_price => winning_price)
        end
        page += 1
      end while !impressions.empty?

      page = 1
      begin
        clicks = Click.paginate_by_sql(click_query, :page => page, :per_page => batch_size)

        clicks.each do |each_click|
          aggregated_detail = AggregatedDetail.find_or_initialize_by_entity_id_and_date_and_entity_type(:entity_id => each_click.entity_id, :date => time.to_date, :entity_type => entity_type)
          aggregated_detail.update_attributes(:clicks_count => each_click.click_count)
        end
        page += 1
      end while !clicks.empty?
      $redis.set("update_aggregated_detail_is_running", 0)
    end
  end

  def self.update_aggregated_details_from_mongo_reports(time,entity_type="advertisement", type="Advertisement", force=false )
    return if force == false # TODO: Temp fixes
    time  = time.to_time
    time = time.localtime
    p time
    param = {}
    param[:type] = type
    # param[:ad_type] = "advertisement"
    param[:ad_type] = "All"
    param[:ad_id] = "All"
    param[:report_sort_by] = "imp_count"
    start_date = time.to_date.beginning_of_day
    end_date = time.to_date.end_of_day

    results = AdImpression.get_results_from_mongo(param, start_date, end_date)

    results.each do |each_result|
      begin
        entity_id = each_result["_id"]
        if entity_id.blank?
          next
        end
        aggregated_detail = AggregatedDetail.find_or_initialize_by_entity_id_and_date_and_entity_type(:entity_id => entity_id, :date => time.to_date, :entity_type => entity_type)
        aggregated_detail.update_attributes(:impressions_count => each_result["imp_count"], :clicks_count => each_result["click_count"], :winning_price => each_result["winning_price"])
      rescue Exception => e
        p "Error While updating aggregated detail"
      end
    end
  end

  def self.update_aggregated_details_from_aggregated_impression(time,entity_type="advertisement", type="Advertisement")
    time  = time.to_time
    time = time.localtime
    p time
    param = {}
    param[:type] = type
    # param[:ad_type] = "advertisement"
    param[:ad_type] = entity_type
    param[:ad_id] = "All"
    param[:report_sort_by] = "imp_count"
    start_date = time.to_date.beginning_of_day
    end_date = time.to_date.end_of_day

    results = AggregatedImpression.get_results_from_agg_impression(param, start_date, end_date)

    if entity_type == "publisher"
      results.each do |each_key, each_val|
        begin
          entity_id = each_key
          if entity_id.blank?
            next
          end
          aggregated_detail = AggregatedDetail.find_or_initialize_by_entity_id_and_date_and_entity_type(:entity_id => entity_id, :date => time.to_date, :entity_type => entity_type)
          aggregated_detail.update_attributes(:impressions_count => each_val["total_imp"], :clicks_count => each_val["total_clicks"], :winning_price => each_val["total_costs"])
        rescue Exception => e
          p "Error While updating aggregated detail"
        end
      end
    else
      results.each do |each_result|
        begin
          entity_id = each_result["_id"]
          if entity_id.blank?
            next
          end
          aggregated_detail = AggregatedDetail.find_or_initialize_by_entity_id_and_date_and_entity_type(:entity_id => entity_id, :date => time.to_date, :entity_type => entity_type)
          aggregated_detail.update_attributes(:impressions_count => each_result["total_imp"], :clicks_count => each_result["total_clicks"], :winning_price => each_result["total_costs_wc"])
        rescue Exception => e
          p "Error While updating aggregated detail"
        end
      end
    end
  end

  def self.update_aggregated_detail_from_mongo(time, entity_type="advertisement", batch_size=1000)
    time = time.localtime
    entity_field = entity_type + "_id"

    match = {"$match" => {"impression_time" => {"$gte" => time.beginning_of_day.utc, "$lte" => time.end_of_day.utc}}}

    match["$match"].merge!("advertisement_type" => "advertisement") #for advertisement

    group =  { "$group" => { "_id" => "$#{entity_field}",
                             "imp_count" => { "$sum" => 1 },
                             "winning_price_sum" => { "$sum" => "$winning_price" },
                             "click_count" => { "$sum" => { "$size" => { "$ifNull" => [ "$m_clicks", [] ] } } }
    }
    }
    sort = {"$sort" => {"_id" => 1}}

    items_by_id = AdImpression.collection.aggregate([match,group,sort])
    items_by_id.collect{|item| item["winning_price_sum"] = (item["winning_price_sum"].to_f/1000000).round(2) }
    items_by_id
  end

  def self.get_counts(date1, date2, publisher_id)
    query = "SELECT sum(impressions_count) as impressions_count, sum(clicks_count) as clicks_count FROM aggregated_details WHERE entity_type='publisher' and entity_id= #{publisher_id} and date BETWEEN '#{date1}' and '#{date2}' group by entity_id"
    results = find_by_sql(query)
    return results
  end

  def self.chart_data_widgets(publisher_id, start_date, end_date, types=[])
    if start_date.nil?
      start_date = 2.weeks.ago
    end

    if end_date.nil?
      end_date = Date.today
    end

    # range = start_date.beginning_of_day..(end_date.end_of_day + 1.day)

    # if start_date.to_date.beginning_of_month.to_s != end_date.to_date.beginning_of_month.to_s
    if (end_date.to_date - start_date.to_date).to_i > 31

      start_date = start_date.beginning_of_month
      end_date = end_date.end_of_month
      # kliks = count(
      #     :group => 'month(date)',
      #     :select => "id",
      #     # :conditions => { :entity_id => publisher_id, :entity_type => 'publisher', :date => range, :advertisement_type => types }  # TODO: have to update based on ad type
      #     :conditions => { :entity_id => publisher_id, :entity_type => 'publisher', :date => range }
      # )

      # results = AggregatedDetail.where(:entity_id => publisher_id, :entity_type => 'publisher', :date => range).select("impressions_count, clicks_count, date").group_by {|each_rec| each_rec.date.month}

      query = "SELECT date, sum(impressions_count) as impressions_count, sum(clicks_count) as clicks_count, sum(winning_price) as winning_price FROM aggregated_details WHERE entity_type='publisher' and entity_id= #{publisher_id} and date BETWEEN '#{start_date}' and '#{end_date}' group by month(date)"
      results = find_by_sql(query).group_by {|each_rec| each_rec.date.month}


      # CREATE JSON DATA FOR EACH MONTH
      (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.map do |date|
        {
            impression_time: date.strftime("%b, %Y"),
            impressions: results[date.month].blank? ? 0 : results[date.month].first.impressions_count,
            clicks: results[date.month].blank? ? 0 : results[date.month].first.clicks_count,
            winning_price: results[date.month].blank? ? 0 : results[date.month].first.winning_price
        }
      end
    else

      query = "SELECT date, sum(impressions_count) as impressions_count, sum(clicks_count) as clicks_count, sum(winning_price) as winning_price FROM aggregated_details WHERE entity_type='publisher' and entity_id= #{publisher_id} and date BETWEEN '#{start_date}' and '#{end_date}' group by date"

      results = find_by_sql(query).group_by {|each_rec| each_rec.date}

      # results = AggregatedDetail.where(:entity_id => publisher_id, :entity_type => 'publisher', :date => range).select("impressions_count, clicks_count, date").group_by(&:date)

      #WORKS FINE DATA FOR EACH DAY
      (start_date.to_date..end_date.to_date).map do |date|
        {
            impression_time: date.strftime("%F"),
            impressions: results[date].blank? ? 0 : results[date].first.impressions_count,
            clicks: results[date].blank? ? 0 : results[date].first.clicks_count,
            winning_price: results[date].blank? ? 0 : results[date].first.winning_price
        }
      end
    end
  end

  def self.chart_data_for_ad(advertisement_id, start_date, end_date, types=[])
    if start_date.nil?
      start_date = 2.weeks.ago
    end

    if end_date.nil?
      end_date = Date.today
    end

    if (end_date.to_date - start_date.to_date).to_i > 31
      start_date = start_date.beginning_of_month
      end_date = end_date.end_of_month

      query = "SELECT date, sum(impressions_count) as impressions_count, sum(clicks_count) as clicks_count, sum(winning_price) as winning_price FROM aggregated_details WHERE entity_type='advertisement' and entity_id= #{advertisement_id} and date BETWEEN '#{start_date}' and '#{end_date}' group by month(date)"
      results = find_by_sql(query).group_by {|each_rec| each_rec.date.month}

      # CREATE JSON DATA FOR EACH MONTH
      (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.map do |date|
        {
            impression_time: date.strftime("%b, %Y"),
            impressions: results[date.month].blank? ? 0 : results[date.month].first.impressions_count,
            clicks: results[date.month].blank? ? 0 : results[date.month].first.clicks_count,
            winning_price: results[date.month].blank? ? 0 : results[date.month].first.winning_price
        }
      end
    else
      query = "SELECT date, sum(impressions_count) as impressions_count, sum(clicks_count) as clicks_count, sum(winning_price) as winning_price FROM aggregated_details WHERE entity_type='advertisement' and entity_id= #{advertisement_id} and date BETWEEN '#{start_date}' and '#{end_date}' group by date"

      results = find_by_sql(query).group_by {|each_rec| each_rec.date}

      #WORKS FINE DATA FOR EACH DAY
      (start_date.to_date..end_date.to_date).map do |date|
        {
            impression_time: date.strftime("%F"),
            impressions: results[date].blank? ? 0 : results[date].first.impressions_count,
            clicks: results[date].blank? ? 0 : results[date].first.clicks_count,
            winning_price: results[date].blank? ? 0 : results[date].first.winning_price
        }
      end
    end
  end

  def self.chart_data_widgets_from_mongo(publisher_id, start_date, end_date)
    publisher_id = publisher_id.to_i
    if start_date.nil?
      start_date = 2.weeks.ago
    end

    if end_date.nil?
      end_date = Date.today
    end

    # if start_date.to_date.beginning_of_month.to_s != end_date.to_date.beginning_of_month.to_s
    if (end_date.to_date - start_date.to_date).to_i > 31
      start_date = start_date.beginning_of_month.to_time
      end_date = end_date.end_of_month.to_time

      imp_project = {"$project" =>  { "year" => { "$year" => "$impression_time"}, "month" => { "$month" => "$impression_time"}, "winning_price" => 1}}
      imp_group =  { "$group" => { "_id" => {"year"=>"$year", "month"=>"$month"}, "winning_price" => {"$sum" => "$winning_price"}, "count" => { "$sum" => 1 } } }
      imp_match = {"$match" => {"impression_time" => {"$gte" => start_date, "$lte" => end_date}, "publisher_id" => publisher_id}}
      imp_sort = {"$sort" => {"_id" => 1}}

      clk_project = {"$project" =>  { "year" => { "$year" => "$timestamp"}, "month" => { "$month" => "$timestamp"}}}
      clk_group =  { "$group" => { "_id" => {"year"=>"$year", "month"=>"$month"}, "count" => { "$sum" => 1 } } }
      clk_match = {"$match" => {"timestamp" => {"$gte" => start_date, "$lte" => end_date}, "publisher_id" => publisher_id}}
      clk_sort = {"$sort" => {"_id" => 1}}

      imp_results = AdImpression.collection.aggregate([imp_match,imp_project,imp_group,imp_sort])
      clk_results = MClick.collection.aggregate([clk_match,clk_project,clk_group,clk_sort])
      return imp_results, clk_results
    else

      #TODO: Have to update
      start_date = start_date.to_time
      end_date = end_date.to_time
      # start_date = Time.new(2014,7,8)
      # end_date = Time.new(2014,7,18)

      imp_project = {"$project" =>  { "month" => { "$month" => "$impression_time"}, "day" => { "$dayOfMonth" => "$impression_time"}, "winning_price" => 1}}
      imp_group =  { "$group" => { "_id" => {"year"=>"$month", "month" => "$day"}, "winning_price" => {"$sum" => "$winning_price"}, "count" => { "$sum" => 1 } } }
      imp_match = {"$match" => {"impression_time" => {"$gte" => start_date, "$lte" => end_date}, "publisher_id" => publisher_id}}
      imp_sort = {"$sort" => {"_id" => 1}}

      clk_project = {"$project" =>  { "month" => { "$month" => "$timestamp"}, "day" => { "$dayOfMonth" => "$timestamp"}}}
      clk_group =  { "$group" => { "_id" => {"year"=>"$month", "month"=>"$day"}, "count" => { "$sum" => 1 } } }
      clk_match = {"$match" => {"timestamp" => {"$gte" => start_date, "$lte" => end_date}, "publisher_id" => publisher_id}}
      clk_sort = {"$sort" => {"_id" => 1}}

      imp_results = AdImpression.collection.aggregate([imp_match,imp_project,imp_group,imp_sort])
      clk_results = MClick.collection.aggregate([clk_match,clk_project,clk_group,clk_sort])
      return imp_results, clk_results
    end
  end

  # def self.chart_data_widgets_for_click(publisher_id, start_date, end_date, types, vendor_id)
  #   if start_date.nil?
  #     start_date = 2.weeks.ago
  #   end
  #
  #   if end_date.nil?
  #     end_date = Date.today
  #   end
  #
  #   range = start_date.beginning_of_day..(end_date.end_of_day + 1.day)
  #
  #   # conditions = { :add_impressions => {:advertisement_type => [types]}, :publisher_id => publisher_id , :timestamp => range, :vendor_id => vendor_id }
  #   conditions = { :entity_id => publisher_id, :entity_type => 'publisher', :date => range }
  #
  #   # conditions.delete(:vendor_id) if vendor_id.blank?
  #
  #   if start_date.to_date.beginning_of_month.to_s != end_date.to_date.beginning_of_month.to_s
  #
  #     kliks = count(
  #
  #         # :joins => [:add_impression],
  #         :group => 'month(date)',
  #         :conditions => conditions
  #     )
  #
  #     # CREATE JSON DATA FOR EACH MONTH
  #     (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.map do |date|
  #       {
  #           impression_time: date.strftime("%b, %Y"),
  #           clicks: kliks[date.month] || 0
  #       }
  #     end
  #
  #
  #   else
  #
  #     kliks = count(
  #         # :joins => [:add_impression],
  #         :group => 'date(date)',
  #         :conditions => conditions
  #     )
  #
  #     #WORKS FINE DATA FOR EACH DAY
  #     (start_date.to_date..end_date.to_date).map do |date|
  #       {
  #           impression_time: date.strftime("%F"),
  #           clicks: kliks[date] || 0
  #       }
  #     end
  #   end
  # end

end
