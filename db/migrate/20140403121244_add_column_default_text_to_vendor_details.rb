class AddColumnDefaultTextToVendorDetails < ActiveRecord::Migration
  def change
    add_column :vendor_details, :default_text, :text
  end
end
