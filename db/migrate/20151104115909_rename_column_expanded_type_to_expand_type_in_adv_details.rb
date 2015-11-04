class RenameColumnExpandedTypeToExpandTypeInAdvDetails < ActiveRecord::Migration
  def up
    rename_column :adv_details, :expanded_type, :expand_type
  end

  def down
    rename_column :adv_details, :expand_type, :expanded_type
  end
end
