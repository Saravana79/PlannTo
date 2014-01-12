class AddImpressionsIdToOrderHistories < ActiveRecord::Migration
  def change
    add_column :order_histories, :impression_id, :int
  end
end
