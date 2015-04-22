class AdImpression
  include Mongoid::Document
  # include Mongoid::Timestamps::Created

  field :advertisement_type, type: String
  field :advertisement_id, type: Integer
  field :impression_id, type: Integer
  field :item_id, type: String
  field :hosted_site_url, type: String
  field :impression_time, type: DateTime
  field :publisher_id, type: Integer
  field :user_id, type: Integer
  # field :ip_address, type: String
  # field :itemsaccess, type: String
  # field :params, type: String
  field :temp_user_id, type: String
  field :sid, type: String
  field :winning_price, type: Float
  field :tagging, type: Integer
  field :retargeting, type: Integer
  field :pre_appearance_count, type: Integer
  field :device, type: String
  field :size, type: String
  field :domain, type: String
  field :design_type, type: String
  field :viewability, type: Integer
  field :additional_details, type: String
  field :video_impression_id, type: String
  field :geo, type: String
  field :is_rii, type: Boolean #is_related_item_impression


  # has_one :m_click
  # embeds_many :m_clicks
  embeds_many :m_clicks
  embeds_many :m_order_histories
  embeds_many :m_companion_impressions

  index({ impression_time: 1 })


  def self.get_results_from_mongo(param, start_date, end_date)
    start_date = start_date
    end_date = end_date
    option = case param[:type]
     when "Sid"
        "$sid"
     when "Temp User ID"
       "$temp_user_id"
     when "Device"
       "$device"
     when "Size"
       "$size"
     when "Domain"
       "$domain"
     when "Pre Appearance Count"
       "$pre_appearance_count"
     when "Viewability"
       "$viewability"
     when "Retargeting"
       "$retargeting"
     when "Design Type"
       "$design_type"
     when "Additional Details"
       "$additional_details"
     when "Hourly"
       {"$hour" => "$impression_time" }
     when "Advertisement"
       "$advertisement_id"
     when "Publisher"
       "$publisher_id"
     when "Is Related Item Impression"
       "$is_rii"
     else
       "$item_id"
     end
    #project = {"$project" =>  { "#{option}" => 1}}


    match = {"$match" => {"impression_time" => {"$gte" => start_date, "$lte" => end_date}}}
    #project = {"$project" =>  { "m_click" => 1, "sid" => 1, "impression_time" => 1, "advertisement_type" => 1, "item_id" => 1, "temp_user_id" => 1, "device" => 1, "size" => 1, "domain" => 1, "design_type" => 1, "pre_appearance_count" => 1}}

    if param[:ad_type] != "All"
      match["$match"].merge!("advertisement_type" => param[:ad_type])
    end

    if param[:ad_id] != "All"
      match["$match"].merge!("advertisement_id" => param[:ad_id].to_i)
    end
    # group =  { "$group" => { "_id" => "$#{option}", "count" => { "$sum" => 1 } } }

    group =  { "$group" => { "_id" => option, "imp_count" => { "$sum" => 1 },
                             "click_count" => { "$sum" => { "$size" => { "$ifNull" => [ "$m_clicks", [] ] } } },
                             "orders_count" => { "$sum" => {"$size" => { "$ifNull" => [ "$m_order_histories", [] ] }} },
                             # "orders_count" => { "$sum" => { "$cond" => [ { "$gte" => [ "$m_order_histories._id", 1 ] }, 1, 0 ] } },
                             # "orders_sum" => { "$sum" => "$m_order_histories.total_revenue" }
                             "orders_sum" => { "$push" => "$m_order_histories.total_revenue" },
                             "winning_price" => {"$sum" => "$winning_price"}
                           }
             }
    # items_by_count = AdImpression.collection.aggregate([project,match,group])

    sort = {"$sort" => {param[:report_sort_by] => -1}}
    limit = {"$limit" => 100}

    items_by_count = AdImpression.collection.aggregate([match,group,sort,limit])

    if option == "$advertisement_id"
      ads = Advertisement.select("id,commission")
      ad_detail_hash = {}

      ads.each do |adv|
        ad_detail_hash.merge!("#{adv.id}" => adv.commission.to_f.round(2))
      end

      items_by_count.each do |each_rep|
        winning_price = each_rep["winning_price"].to_f
        winning_price = winning_price/1000000
        commission = ad_detail_hash[each_rep["_id"].to_s]

        commission = commission.blank? ? 1 : commission.to_f
        winning_price = winning_price.to_f + (winning_price.to_f * (commission/100))

        each_rep["winning_price"] = winning_price.to_f.round(2)
      end
    else
      items_by_count.each do |each_rep|
        winning_price = each_rep["winning_price"].to_f
        winning_price = winning_price/1000000

        each_rep["winning_price"] = winning_price.to_f.round(2)
      end
    end
    items_by_count
    # items_by_count = AdImpression.collection.aggregate([match,project,group,sort,limit])
  end

  def self.remove_old_mongodb_values()
    delete_count = AdImpression.delete_all(conditions: {"impression_time" => {"$lte" => 2.weeks.ago}})
    p delete_count

    delete_count = AdImpression.delete_all(conditions: {"impression_time" => {"$lte" => 1.day.ago}, "advertisement_id" => {"$eq" => nil} })
    p delete_count
  end
end