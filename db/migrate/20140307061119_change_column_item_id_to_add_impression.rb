class ChangeColumnItemIdToAddImpression < ActiveRecord::Migration
  def up
    change_column :add_impressions, :item_id, :string
  end

  def down
    change_column :add_impressions, :item_id, :integer
  end
end
