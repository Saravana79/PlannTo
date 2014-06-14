class AddColumnPlanntoPercentageAndPlanntoAmountToPaymentReport < ActiveRecord::Migration
  def change
    add_column :payment_reports, :plannto_percentage, :float
    add_column :payment_reports, :plannto_amount, :float
  end
end
