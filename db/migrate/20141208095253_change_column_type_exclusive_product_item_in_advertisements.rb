class ChangeColumnTypeExclusiveProductItemInAdvertisements < ActiveRecord::Migration
  def up
    change_column :advertisements, :exclusive_item_ids, :text
  end

  def down
    change_column :advertisements, :exclusive_item_ids, :string
  end
end
