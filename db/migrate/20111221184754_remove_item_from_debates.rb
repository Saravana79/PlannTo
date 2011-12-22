class RemoveItemFromDebates < ActiveRecord::Migration
  def change
    remove_column :debates, :item_id
  end
end
