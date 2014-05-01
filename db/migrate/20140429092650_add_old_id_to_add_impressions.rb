class AddOldIdToAddImpressions < ActiveRecord::Migration
  def change
    add_column :add_impressions, :old_id, :integer
  end
end
