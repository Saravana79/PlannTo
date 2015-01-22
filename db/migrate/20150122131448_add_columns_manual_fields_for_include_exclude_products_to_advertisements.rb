class AddColumnsManualFieldsForIncludeExcludeProductsToAdvertisements < ActiveRecord::Migration
  def change
    add_column :advertisements, :man_exclusive_item_ids, :text
    add_column :advertisements, :man_included_item_ids, :text
  end
end
