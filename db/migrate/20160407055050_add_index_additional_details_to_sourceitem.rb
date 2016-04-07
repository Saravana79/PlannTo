class AddIndexAdditionalDetailsToSourceitem < ActiveRecord::Migration
  def change
    add_index :sourceitems, :additional_details
  end
end
