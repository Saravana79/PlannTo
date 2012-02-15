class CreateContentItemRelations < ActiveRecord::Migration
  def change
    create_table :content_item_relations do |t|
      t.integer    :content_id, :null => false
      t.integer    :item_id, :null => false
      t.timestamps
    end
  end
end
