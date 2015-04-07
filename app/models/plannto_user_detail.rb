class PlanntoUserDetail
  include Mongoid::Document
  # include Mongoid::Timestamps::Created

  field :plannto_user_id, type: String
  field :gender, type: String
  field :google_user_id, type: String

  embeds_many :m_item_types
  # embeds_many :m_items
end