class CreateItemContentsRelationsCaches < ActiveRecord::Migration
  def change
    create_table :item_contents_relations_cache do |t|
      t.integer :item_id
      t.integer :content_id
      t.timestamps
    end
  end
end
