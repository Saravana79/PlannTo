class ChangeColumnImpressionIdToClickAndOrderHistory < ActiveRecord::Migration
  def up
    change_column :clicks, :impression_id, :uuid
    change_column :order_histories, :impression_id, :uuid
  end

  def down
    change_column :clicks, :impression_id, :integer
    change_column :order_histories, :impression_id, :integer
  end
end
