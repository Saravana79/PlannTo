class CreateAttributeValues < ActiveRecord::Migration
  def change
    create_table :attribute_values do |t|
      t.integer   :attribute_id, :null => false
      t.integer   :item_id, :null => false
      t.string    :value, :limit => 5000, :null => false
      t.string    :addition_comment, :limit => 5000
      t.boolean   :is_visible, :default => true

      t.timestamps
    end
  end
end
