class MItem
  include Mongoid::Document
  # include Mongoid::Timestamps::Created

  field :item_id, type: Integer
  field :lad, type: Date # last accessed date
  # field :ranking, type: Integer # Ranking
  field :rk, type: Integer # Ranking #ranking

  embedded_in :i_type
end