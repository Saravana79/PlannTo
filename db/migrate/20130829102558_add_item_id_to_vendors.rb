class AddItemIdToVendors < ActiveRecord::Migration
  def change
    add_column :vendors,:item_id,:integer
  end
end
