class ChangeColumnRevenueToDecimalInOrderHistory < ActiveRecord::Migration
  def up
    change_column :order_histories, :total_revenue, :decimal, :precision => 10, :scale => 2
  end

  def down
    change_column :order_histories, :total_revenue, :float
  end
end
