class CreateCategoryItemDetails < ActiveRecord::Migration
  def change
    create_table :category_item_details do |t|
      t.string :item_type
      t.string :category
      t.string :sub_category
      t.text :text
      t.text :link
      t.timestamps
    end
  end
end
