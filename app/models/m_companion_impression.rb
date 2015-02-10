class MCompanionImpression
  include Mongoid::Document

  field :timestamp, type: DateTime
  field :video_impression_id, type: String

  # belongs_to :ad_impression
  embedded_in :ad_impression
end