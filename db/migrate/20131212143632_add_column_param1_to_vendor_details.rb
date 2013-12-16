class AddColumnParam1ToVendorDetails < ActiveRecord::Migration
  def change
  	 add_column :vendor_details, :param1, :string
  end
end
