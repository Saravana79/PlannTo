class CreateAttributesRelationships < ActiveRecord::Migration
  def change
    create_table :attributes_relationships do |t|
      t.integer :attribute_id
      t.integer :itemtype_id
      t.integer :Priority
      t.boolean :is_filterable

      t.timestamps
    end
  end
end
