class AddPaymentDateToOrderHistories < ActiveRecord::Migration
  def change
    add_column :order_histories, :payment_date, :datetime
  end
end
