class AddColumnsRelatedItemsToItemAdvertisements < ActiveRecord::Migration
  def change
    add_column :advertisements, :having_related_items, :boolean, :default => false
    add_column :advertisements, :related_item_ids, :text
  end
end
