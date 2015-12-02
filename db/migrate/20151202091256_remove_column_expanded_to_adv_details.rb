class RemoveColumnExpandedToAdvDetails < ActiveRecord::Migration
  def up
    remove_column :adv_details, :expanded
  end

  def down
    add_column :adv_details, :expanded, :boolean, :default => false
  end
end
