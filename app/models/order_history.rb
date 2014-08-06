class OrderHistory < ActiveRecord::Base
  validates :order_date, :total_revenue, :vendor_ids, presence: true

  belongs_to :add_impression, :foreign_key => :impression_id
  belongs_to :vendor, :foreign_key => :vendor_ids
  belongs_to :payment_report
  belongs_to :advertisement
end
