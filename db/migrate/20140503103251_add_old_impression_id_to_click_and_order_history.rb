class AddOldImpressionIdToClickAndOrderHistory < ActiveRecord::Migration
  def change
    add_column :clicks, :old_impression_id, :integer
    add_column :order_histories, :old_impression_id, :integer
  end
end
