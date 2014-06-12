class AddColumnPaymentReportIdToOrderHistories < ActiveRecord::Migration
  def change
    add_column :order_histories, :payment_report_id, :integer
  end
end
