class AddVendorIdsToPublishers < ActiveRecord::Migration
  def change
    add_column :publishers,:vendor_ids,:string
  end
end
