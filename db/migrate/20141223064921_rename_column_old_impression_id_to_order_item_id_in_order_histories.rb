class RenameColumnOldImpressionIdToOrderItemIdInOrderHistories < ActiveRecord::Migration
  def up
    rename_column :order_histories, :old_impression_id, :order_item_id
  end

  def down
    rename_column :order_histories, :order_item_id, :old_impression_id
  end
end
