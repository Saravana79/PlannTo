class AddIndexToSourceCategories < ActiveRecord::Migration
  def change
    add_index :source_categories, :source
  end
end
