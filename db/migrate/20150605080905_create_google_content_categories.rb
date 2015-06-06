class CreateGoogleContentCategories < ActiveRecord::Migration
  def change
    create_table :google_content_categories do |t|
      t.integer :category_id
      t.integer :parent_id
      t.string :category
      t.string :plannto_category
      t.timestamps
    end
  end
end
