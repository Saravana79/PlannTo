class CreateTopicItemtypeRelations < ActiveRecord::Migration
  def change
    create_table :topic_itemtype_relations do |t|
      t.integer :item_id
      t.integer :itemtype_id

      t.timestamps
    end
  end
end
