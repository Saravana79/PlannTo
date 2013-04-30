class AddColumnsToItems < ActiveRecord::Migration
  def change
    add_column :items,:new_version_item_id,:integer
    add_column :items,:alternative_name,:string
    add_column :items,:hidden_alternative_name, :string
  end
end
