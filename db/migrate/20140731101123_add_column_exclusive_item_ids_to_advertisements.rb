class AddColumnExclusiveItemIdsToAdvertisements < ActiveRecord::Migration
  def change
    add_column :advertisements, :exclusive_item_ids, :string
  end
end
