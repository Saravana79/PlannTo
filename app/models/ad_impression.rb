class AdImpression
  include Mongoid::Document
  include Mongoid::Timestamps

  field :advertisement_type, type: String
  field :advertisement_id, type: Integer
  field :impression_id, type: Integer
  field :item_id, type: String
  field :hosted_site_url, type: String
  field :impression_time, type: DateTime
  field :publisher_id, type: Integer
  field :user_id, type: Integer
  field :ip_address, type: String
  # field :created_at, type: DateTime
  # field :updated_at, type: DateTime
  field :itemsaccess, type: String
  field :params, type: String
  field :temp_user_id, type: String
  field :sid, type: String
  field :winning_price, type: Float

  has_one :m_click
end