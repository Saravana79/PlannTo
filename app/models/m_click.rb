class MClick
  include Mongoid::Document
  include Mongoid::Timestamps

  field :ad_impression_id, type: String
  field :click_url, type: String
  field :hosted_site_url, type: String
  field :timestamp, type: DateTime
  field :item_id, type: Integer
  field :user_id, type: Integer
  field :ipaddress, type: String
  field :publisher_id, type: Integer
  field :vendor_id, type: Integer
  field :source_type, type: String
  field :temp_user_id, type: String
  field :old_impression_id, type: Integer
  field :advertisement_id, type: Integer
  field :sid, type: String

  belongs_to :ad_impression
end