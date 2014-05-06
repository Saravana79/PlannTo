class OrderHistory < ActiveRecord::Base
  belongs_to :vendor, :foreign_key => :vendor_ids
end
