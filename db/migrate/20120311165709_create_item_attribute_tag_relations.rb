class CreateItemAttributeTagRelations < ActiveRecord::Migration
  def change
    create_table :item_attribute_tag_relations do |t|
      t.integer   :attribute_id, :null => false
      t.integer   :item_id, :null => false
      t.string    :value, :limit => 5000, :null => false
      t.integer   :itemtype_id, :null => false
      t.timestamps
    end
  end
end
