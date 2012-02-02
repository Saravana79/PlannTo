class CreateRelatedItems < ActiveRecord::Migration
  def change
    create_table :related_items do |t|
      t.integer :item_id
      t.string :related_item_ids
      t.integer :priority

      t.timestamps
    end
  end
end
