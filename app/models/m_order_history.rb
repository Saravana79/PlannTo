class MOrderHistory
  include Mongoid::Document

  field :total_revenue, type: Float
  field :order_history_id, type: Integer

  embedded_in :ad_impression
end