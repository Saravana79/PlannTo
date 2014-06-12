class PaymentReport < ActiveRecord::Base
  validates :publisher_id, :presence => true

  has_many :order_histories
end
