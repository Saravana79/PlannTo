class AddColumnExcludeDendorIdsIntoPublishers < ActiveRecord::Migration
  def change
  	 add_column :publishers, :exclude_vendor_ids, :string
  end
end
