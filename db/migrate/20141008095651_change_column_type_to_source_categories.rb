class ChangeColumnTypeToSourceCategories < ActiveRecord::Migration
  def up
    change_column :source_categories, :check_details, :text
    remove_column :source_categories, :generic_details
  end

  def down
    change_column :source_categories, :check_details, :string
    add_column :source_categories, :generic_details, :string
  end
end
