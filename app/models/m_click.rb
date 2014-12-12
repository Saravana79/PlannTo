class MClick
  include Mongoid::Document
  # include Mongoid::Timestamps::Created

  # field :ad_impression_id, type: String
  field :click_url, type: String
  field :hosted_site_url, type: String
  field :timestamp, type: DateTime
  field :item_id, type: Integer
  field :user_id, type: Integer
  # field :ipaddress, type: String
  field :publisher_id, type: Integer
  field :vendor_id, type: Integer
  field :source_type, type: String
  field :temp_user_id, type: String
  # field :old_impression_id, type: Integer
  field :advertisement_id, type: Integer
  field :sid, type: String

  #click details
  field :tagging, type: Integer
  field :retargeting, type: Integer
  field :pre_appearance_count, type: Integer
  field :additional_details, type: String

  # belongs_to :ad_impression
  embedded_in :ad_impression
end