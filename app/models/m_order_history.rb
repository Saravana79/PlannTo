class MOrderHistory
  include Mongoid::Document
  include Mongoid::Timestamps

  field :order_date, type: DateTime
  field :no_of_orders, type: Integer
  field :total_revenue, type: Float
  field :publisher_id, type: Integer
  field :vendor_ids, type: Integer
  field :order_status, type: String
  field :payment_status, type: String
  field :item_id, type: Integer
  field :item_name, type: String
  field :product_price, type: String
  field :ad_impression_id, type: String
  field :old_impression_id, type: Integer
  field :payment_date, type: DateTime
  field :payment_report_id, type: Integer
  field :sid, type: String
  field :advertisement_id, type: Integer
end