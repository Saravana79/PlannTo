class OrderHistory < ActiveRecord::Base
  validates :order_date, :total_revenue, :vendor_ids, presence: true

  belongs_to :vendor, :foreign_key => :vendor_ids
end
