class AddIndexItemIdToItemAdDetails < ActiveRecord::Migration
  def change
    add_index :item_ad_details, :item_id
  end
end
