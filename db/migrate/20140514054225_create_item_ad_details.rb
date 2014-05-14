class CreateItemAdDetails < ActiveRecord::Migration
  def change
    create_table :item_ad_details do |t|
      t.integer :item_id
      t.integer :impressions
      t.integer :clicks
      t.float :ectr
      t.string :related_item_ids
      t.integer :new_version_id
      t.integer :old_version_id

      t.timestamps
    end
  end
end
