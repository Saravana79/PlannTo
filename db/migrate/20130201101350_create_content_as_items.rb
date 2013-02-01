class CreateContentAsItems < ActiveRecord::Migration
  def change
    create_table :content_as_items do |t|
      t.integer :content_id
      t.integer :item_id
      t.timestamps
    end
  end
end
