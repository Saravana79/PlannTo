class AddColumnVendorIdToItemDetailOthers < ActiveRecord::Migration
  def change
    add_column :item_detail_others, :vendor_id, :integer
  end
end
