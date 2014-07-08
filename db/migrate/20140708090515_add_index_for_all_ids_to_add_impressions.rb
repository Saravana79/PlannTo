class AddIndexForAllIdsToAddImpressions < ActiveRecord::Migration
  def change
    add_index :add_impressions, :impression_id
    add_index :add_impressions, :user_id
    add_index :add_impressions, :item_id
    add_index :add_impressions, :impression_time
  end
end
