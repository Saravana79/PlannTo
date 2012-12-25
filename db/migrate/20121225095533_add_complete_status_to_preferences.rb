class AddCompleteStatusToPreferences < ActiveRecord::Migration
  def change
    add_column :buying_plans,:completed,:boolean,:default => false
    add_column :buying_plans,:owned_item_id,:integer
    add_column :buying_plans,:owned_item_description,:text
  end
end
