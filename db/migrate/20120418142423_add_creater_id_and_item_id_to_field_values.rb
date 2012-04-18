class AddCreaterIdAndItemIdToFieldValues < ActiveRecord::Migration
  def change
    add_column :field_values, :user_id, :integer
    add_column :field_values, :item_id, :integer
  end
end
