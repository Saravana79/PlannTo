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


  has_one :m_click


  def self.get_results_from_mongo(param)
    option = case param[:type]
     when "Sid"
        "sid"
     when "Temp User ID"
       "temp_user_id"
     else
       "item_id"
     end
    #project = {"$project" =>  { "#{option}" => 1}}


    match = {"$match" => {"advertisement_type" => "advertisement"}}
    if param[:ad_id] != "All"
      match["$match"].merge!("advertisement_id" => param[:ad_id].to_i)
    end
    group =  { "$group" => { "_id" => "$#{option}", "count" => { "$sum" => 1 } } }
    sort = {"$sort" => {"count" => -1}}
    limit = {"$limit" => 100}

    # items_by_count = AdImpression.collection.aggregate([project,group,sort,limit])
    items_by_count = AdImpression.collection.aggregate([match,group,sort,limit])
  end
end