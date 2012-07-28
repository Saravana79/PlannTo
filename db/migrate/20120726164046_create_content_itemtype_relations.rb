class CreateContentItemtypeRelations < ActiveRecord::Migration
  def change
    create_table :content_itemtype_relations do |t|
      t.integer :itemtype_id
      t.integer :content_id

      t.timestamps
    end
  end
end
