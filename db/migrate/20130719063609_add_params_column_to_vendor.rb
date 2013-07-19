class AddParamsColumnToVendor < ActiveRecord::Migration
  def change
    add_column :vendors,:params,:string
  end
end
