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


  # has_one :m_click
  embeds_one :m_click
  embeds_many :m_order_histories

  index({ impression_time: 1 })


  def self.get_results_from_mongo(param, start_date, end_date)
    start_date = start_date
    end_date = end_date
    option = case param[:type]
     when "Sid"
        "sid"
     when "Temp User ID"
       "temp_user_id"
     when "Device"
       "device"
     when "Size"
       "size"
     when "Domain"
       "domain"
     when "Pre Appearance Count"
       "pre_appearance_count"
     when "Viewability"
       "viewability"
     when "Retargeting"
       "retargeting"
     else
       "item_id"
     end
    #project = {"$project" =>  { "#{option}" => 1}}


    match = {"$match" => {"impression_time" => {"$gte" => start_date, "$lte" => end_date}}}
    #project = {"$project" =>  { "m_click" => 1, "sid" => 1, "impression_time" => 1, "advertisement_type" => 1, "item_id" => 1, "temp_user_id" => 1, "device" => 1, "size" => 1, "domain" => 1, "design_type" => 1, "pre_appearance_count" => 1}}

    if param[:ad_id] != "All"
      match["$match"].merge!("advertisement_id" => param[:ad_id].to_i)
    end
    # group =  { "$group" => { "_id" => "$#{option}", "count" => { "$sum" => 1 } } }

    group =  { "$group" => { "_id" => "$#{option}", "imp_count" => { "$sum" => 1 },
                             "click_count" => { "$sum" => { "$cond" => [ { "$gte" => [ "$m_click._id", 1 ] }, 1, 0 ] } },
                             "orders_count" => { "$sum" => {"$size" => { "$ifNull" => [ "$m_order_histories", [] ] }} },
                             # "orders_count" => { "$sum" => { "$cond" => [ { "$gte" => [ "$m_order_histories._id", 1 ] }, 1, 0 ] } },
                             # "orders_sum" => { "$sum" => "$m_order_histories.total_revenue" }
                             "orders_sum" => { "$push" => "$m_order_histories.total_revenue" }
                           }
             }
    # items_by_count = AdImpression.collection.aggregate([project,match,group])

    sort = {"$sort" => {param[:report_sort_by] => -1}}
    limit = {"$limit" => 100}

    items_by_count = AdImpression.collection.aggregate([match,group,sort,limit])
    # items_by_count = AdImpression.collection.aggregate([match,project,group,sort,limit])
  end
end