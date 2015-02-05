class MCompanionImpression
  include Mongoid::Document

  field :timestamp, type: DateTime

  # belongs_to :ad_impression
  embedded_in :ad_impression
end