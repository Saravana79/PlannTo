class AlterUserVendorTable < ActiveRecord::Migration
  def up
    remove_column :user_vendors, :vendor_id
    add_column :user_vendors,:relationship_type,:string
    add_column :user_vendors,:relationship_id,:integer
  end

  def down
  end
end
