class AggregatedImpression
  include Mongoid::Document

  field :agg_date, type: Date
  field :ad_id, type: Integer
  field :for_pub, type: Boolean
  field :total_imp, type: Integer
  field :total_clicks, type: Integer
  field :total_orders, type: Integer
  field :total_product_price, type: Float
  field :tot_valid_orders, type: Integer # total_validated_orders
  field :tot_valid_product_price, type: Float # total_validated_product_price
  field :total_costs, type: Float
  field :total_costs_wc, type: Float #Total costs with commission
  field :publishers, type: Hash
  field :hours, type: Hash
  field :device, type: Hash #Device True or False
  field :ret, type: Hash #Retargetting True or False
  field :rii, type: Hash #Related Item Impression True or False
  field :size, type: Hash #Related Item Impression True or False
  field :page_types, type: Hash #Page types hash
  field :visited, type: Hash #Related Item Impression True or False
  field :expanded, type: Hash #Related Item Impression True or False

  # field :hours, type: Array
  # [*0..23].each do |each_hour|
  #   field "hour_#{each_hour}".to_sym, type: Integer
  # end

  def self.get_results_from_agg_impression(param, start_date, end_date)
    if !param[:ad_id].is_a?(Array)
      param[:ad_id] = param[:ad_id].to_s.split(",")
    end

    if param[:type] == "Advertisement"
      option = "$ad_id"
      match = {"$match" => {"agg_date" => {"$gte" => start_date, "$lte" => end_date}}}

      if param[:ad_type] == "advertisement"
        match["$match"].merge!("for_pub" => nil, "ad_id" => {"$ne" => nil})
      else
        match["$match"].merge!("for_pub" => true)
      end

      if !param[:ad_id].include?("All")
        ad_ids = param[:ad_id].compact.map(&:to_i)
        match["$match"].merge!("ad_id" => {"$in" => ad_ids})
      end

      group =  { "$group" => { "_id" => option, "total_imp" => { "$sum" => "$total_imp" }, "total_clicks" => { "$sum" => "$total_clicks" },
                               "total_orders" => { "$sum" => "$total_orders" }, "total_product_price" => { "$sum" => "$total_product_price" },
                               "tot_valid_orders" => { "$sum" => "$tot_valid_orders" }, "tot_valid_product_price" => { "$sum" => "$tot_valid_product_price" },
                               "total_costs" => { "$sum" => "$total_costs" }, "total_costs_wc" => { "$sum" => "$total_costs_wc" }#,
                               # "click_count" => { "$sum" => { "$size" => { "$ifNull" => [ "$m_clicks", [] ] } } },
                               # "orders_count" => { "$sum" => {"$size" => { "$ifNull" => [ "$m_order_histories", [] ] }} },
                               # "orders_count" => { "$sum" => { "$cond" => [ { "$gte" => [ "$m_order_histories._id", 1 ] }, 1, 0 ] } },
                               # "orders_sum" => { "$sum" => "$m_order_histories.total_revenue" }
                               # "orders_sum" => { "$push" => "$m_order_histories.total_revenue" },
      }
      }

      results = AggregatedImpression.collection.aggregate([match,group])

      if (!param[:ad_id].include?("All") && results.count > 1)
        tot_hash = {}
        results.each_with_index do |each_result, index|
          each_result.each do |key, value|
            if index == 0
              tot_hash[key] = value
            else
              tot_hash[key] = tot_hash[key] + value
            end
          end
        end
        tot_hash["_id"] = "Total"
        results << tot_hash
      end
    else
      query = {}

      if start_date.to_date == end_date.to_date
        query[:agg_date] = start_date.to_date
      else
        query[:agg_date.gte] = start_date.to_date
        query[:agg_date.lte] = end_date.to_date
      end

      if ["Domain", "Item", "Sid"].include?(param[:type])
        query[:agg_type] = param[:type]
        if param[:ad_type] == "advertisement"
          if !param[:ad_id].include?("All")
            ad_ids = param[:ad_id].compact.map(&:to_i)
            # match["$match"].merge!("ad_id" => {"$in" => ad_ids})
            query[:ad_id.in] = ad_ids
          else
            query[:ad_id.ne] = nil
          end
        end
        results = AggregatedImpressionByType.where(query)
      else
        if param[:ad_type] == "advertisement"
          query[:for_pub] = nil
          if !param[:ad_id].include?("All")
            ad_ids = param[:ad_id].compact.map(&:to_i)
            # match["$match"].merge!("ad_id" => {"$in" => ad_ids})
            query[:ad_id.in] = ad_ids
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
        when "Size"
          "size"
        when "Sid"
          "agg_coll"
        when "Page Type"
          "page_types"
      end

      result_hash = results.map(&:"#{option}")

      final_hash = {}
      result_hash = result_hash.compact

      if option == "page_types"
        result_hash.each do |each_hash|
          each_hash.each do |key, each_val|
            each_val.each do |each_key, val|
              final_hash[key] = {} if final_hash[key].blank?
              final_hash[key]["total_imp"] = final_hash[key]["total_imp"].to_i + val["imp"].to_i
              final_hash[key]["total_clicks"] = final_hash[key]["total_clicks"].to_i + val["clicks"].to_i
              final_hash[key]["total_orders"] = final_hash[key]["total_orders"].to_i + val["orders"].to_i
              final_hash[key]["total_costs"] = (final_hash[key]["total_costs"].to_f + val["costs"].to_f).round(2)
              final_hash[key]["total_product_price"] = (final_hash[key]["total_product_price"].to_f + val["product_price"].to_f).round(2)
              final_hash[key]["tot_valid_orders"] = final_hash[key]["tot_valid_orders"].to_i + val["orders"].to_i
              final_hash[key]["tot_valid_product_price"] = (final_hash[key]["tot_valid_product_price"].to_f + val["product_price"].to_f).round(2)
            end
          end
        end
      else
        result_hash.each do |each_hash|
          each_hash.each do |key, val|
            final_hash[key] = {} if final_hash[key].blank?
            final_hash[key]["total_imp"] = final_hash[key]["total_imp"].to_i + val["imp"].to_i
            final_hash[key]["total_clicks"] = final_hash[key]["total_clicks"].to_i + val["clicks"].to_i
            final_hash[key]["total_orders"] = final_hash[key]["total_orders"].to_i + val["orders"].to_i
            final_hash[key]["total_costs"] = (final_hash[key]["total_costs"].to_f + val["costs"].to_f).round(2)
            final_hash[key]["total_product_price"] = (final_hash[key]["total_product_price"].to_f + val["product_price"].to_f).round(2)
            final_hash[key]["tot_valid_orders"] = final_hash[key]["tot_valid_orders"].to_i + val["orders"].to_i
            final_hash[key]["tot_valid_product_price"] = (final_hash[key]["tot_valid_product_price"].to_f + val["product_price"].to_f).round(2)
          end
        end
      end

      results = final_hash
      sort_by = param[:sort_by]
      sort_by = "total_imp" if sort_by.blank?

      results = Hash[results.sort_by {|_, v| v[sort_by].to_i}.reverse]
    end
    results
  end

  def self.update_from_redis_for_widget
    today_date = Date.today.to_s
    yesterday_date = Date.yesterday.to_s
    keys = $redis.keys("publisher_*#{today_date}") + $redis.keys("publisher_*#{yesterday_date}")

    keys.each do |each_key|
      val = $redis.get(each_key)
      splitted_key = each_key.to_s.split("_")

      agg_imp = AggregatedImpression.where(:agg_date => splitted_key[2], :ad_id => nil, :for_pub => true).last

      if agg_imp.blank?
        agg_imp = AggregatedImpression.new(:agg_date => splitted_key[2], :ad_id => nil, :for_pub => true, :publishers => {splitted_key[1].to_s => {"imp" => val}}, :total_imp => val)
        agg_imp.save!
      else
        publishers = agg_imp.publishers
        publishers = {} if publishers.blank?
        publisher_val = publishers[splitted_key[1].to_s]
        if publisher_val.blank?
          publishers[splitted_key[1].to_s] = {}
          publisher_val = publishers[splitted_key[1].to_s]
          publisher_val["imp"] = val
        else
          publisher_val["imp"] = val
        end
        # publishers.merge!(splitted_key[1].to_s => {"imp" => val})
        agg_imp.publishers = publishers
        agg_imp.total_imp = publishers.values.map {|d| d["imp"].to_i}.compact.sum
        agg_imp.save!
      end
    end
  end

end