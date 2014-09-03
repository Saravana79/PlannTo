class CreateSourceCategories < ActiveRecord::Migration
  def change
    create_table :source_categories do |t|
      t.string :source
      t.string :categories
      t.boolean :have_mobile_site, :default => false
      t.timestamps
    end
  end
end
