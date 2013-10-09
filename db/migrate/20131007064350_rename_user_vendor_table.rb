class RenameUserVendorTable < ActiveRecord::Migration
  def up
    rename_table :user_vendors, :user_relationships
  end

  def down
    rename_table :user_relationships, :user_vendors
  end
end
