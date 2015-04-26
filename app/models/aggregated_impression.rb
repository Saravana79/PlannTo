class AggregatedImpression
  include Mongoid::Document

  field :agg_date, type: Date
  field :ad_id, type: Integer
  field :for_pub, type: Boolean
  field :publishers, type: Hash
  field :hours, type: Hash
  field :device, type: Hash #Device True or False
  field :ret, type: Hash #Retargetting True or False
  field :rii, type: Hash #Related Item Impression True or False

  # field :hours, type: Array
  # [*0..23].each do |each_hour|
  #   field "hour_#{each_hour}".to_sym, type: Integer
  # end

end