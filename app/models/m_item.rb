class MItem
  include Mongoid::Document
  # include Mongoid::Timestamps::Created

  field :item_id, type: Integer
  field :lad, type: Date # last accessed date
  field :ranking, type: Integer # Ranking

  embedded_in :m_item_type
end