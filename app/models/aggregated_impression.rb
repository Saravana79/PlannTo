class AggregatedImpression
  include Mongoid::Document

  field :agg_date, type: Date
  field :ad_id, type: Integer
  field :for_pub, type: Boolean
  field :total_imp, type: Integer
  field :total_clicks, type: Integer
  field :total_orders, type: Integer
  field :total_costs, type: Float
  field :total_costs_wc, type: Float #Total costs with commission
  field :publishers, type: Hash
  field :hours, type: Hash
  field :device, type: Hash #Device True or False
  field :ret, type: Hash #Retargetting True or False
  field :rii, type: Hash #Related Item Impression True or False

  # field :hours, type: Array
  # [*0..23].each do |each_hour|
  #   field "hour_#{each_hour}".to_sym, type: Integer
  # end

  def self.get_results_from_agg_impression(param, start_date, end_date)
    if param[:type] == "Advertisement"
      option = "$ad_id"
      match = {"$match" => {"agg_date" => {"$gte" => start_date, "$lte" => end_date}}}

      if param[:ad_type] == "advertisement"
        match["$match"].merge!("for_pub" => nil, "ad_id" => {"$ne" => nil})
      else
        match["$match"].merge!("for_pub" => true)
      end

      if param[:ad_id] != "All"
        match["$match"].merge!("ad_id" => param[:ad_id].to_i)
      end

      group =  { "$group" => { "_id" => option, "total_imp" => { "$sum" => "$total_imp" }, "total_clicks" => { "$sum" => "$total_clicks" },
                               "total_orders" => { "$sum" => "$total_orders" }, "total_costs" => { "$sum" => "$total_costs" }, "total_costs_wc" => { "$sum" => "$total_costs_wc" }#,
                               # "click_count" => { "$sum" => { "$size" => { "$ifNull" => [ "$m_clicks", [] ] } } },
                               # "orders_count" => { "$sum" => {"$size" => { "$ifNull" => [ "$m_order_histories", [] ] }} },
                               # "orders_count" => { "$sum" => { "$cond" => [ { "$gte" => [ "$m_order_histories._id", 1 ] }, 1, 0 ] } },
                               # "orders_sum" => { "$sum" => "$m_order_histories.total_revenue" }
                               # "orders_sum" => { "$push" => "$m_order_histories.total_revenue" },
      }
      }

      results = AggregatedImpression.collection.aggregate([match,group])
    else
      query = {}

      if start_date.to_date == end_date.to_date
        query[:agg_date] = start_date.to_date
      else
        query[:agg_date.gte] = start_date.to_date
        query[:agg_date.lte] = end_date.to_date
      end

      if ["Domain", "Item"].include?(param[:type])
        query[:agg_type] = param[:type]
        if param[:ad_type] == "advertisement"
          if param[:ad_id] != "All"
            query[:ad_id] = param[:ad_id].to_i
          else
            query[:ad_id.ne] = nil
          end
        end
        results = AggregatedImpressionByType.where(query)
      else
        if param[:ad_type] == "advertisement"
          query[:for_pub] = nil
          if param[:ad_id] != "All"
            query[:ad_id] = param[:ad_id].to_i
          else
            query[:ad_id.ne] = nil
          end
        elsif param[:ad_type] == "non advertisement"
          query[:for_pub] = true
        end
        results = AggregatedImpression.where(query)
      end

      option = case param[:type]
        when "Device"
        "device"
        when "Retargeting"
        "ret"
        when "Hourly"
        "hours"
        when "Publisher"
        "publishers"
        when "Is Related Item Impression"
        "rii"
        when "Domain"
        "agg_coll"
        when "Item"
        "agg_coll"
      end

      result_hash = results.map(&:"#{option}")

      final_hash = {}
      result_hash = result_hash.compact

      result_hash.each do |each_hash|
        each_hash.each do |key, val|
          final_hash[key] = {} if final_hash[key].blank?
          final_hash[key]["total_imp"] = final_hash[key]["total_imp"].to_i + val["imp"].to_i
          final_hash[key]["total_clicks"] = final_hash[key]["total_clicks"].to_i + val["clicks"].to_i
          final_hash[key]["total_orders"] = final_hash[key]["total_orders"].to_i + val["orders"].to_i
          final_hash[key]["total_costs"] = (final_hash[key]["total_costs"].to_f + val["costs"].to_f).round(2)
        end
      end

      results = final_hash

      results = Hash[results.sort_by {|_, v| v["total_imp"].to_i}.reverse]
    end
    results
  end

end