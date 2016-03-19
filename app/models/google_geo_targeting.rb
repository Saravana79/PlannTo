class GoogleGeoTargeting < ActiveRecord::Base

  def self.get_location_id_hash_list
    google_geo_targeting_hash = {}
    GoogleGeoTargeting.where("location_id is not null").each {|each_val| google_geo_targeting_hash.merge!(each_val.criteria_id.to_s => each_val.location_id)}
    google_geo_targeting_hash
  end
end
