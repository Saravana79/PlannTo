class CreateRelatedItems < ActiveRecord::Migration
  def change
    create_table :related_items do |t|
      t.integer :item_id
      t.integer :related_item_id
      t.integer :variance

      t.timestamps
    end
  end
end
