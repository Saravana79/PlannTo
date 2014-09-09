class AddCoulumnPrefixToSourceCategory < ActiveRecord::Migration
  def change
    add_column :source_categories, :prefix, :string
  end
end
