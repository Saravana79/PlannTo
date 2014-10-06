class AddColumnToSourceCategroy < ActiveRecord::Migration
  def change
    add_column :source_categories, :title_check, :boolean
    add_column :source_categories, :check_details, :string
    add_column :source_categories, :generic_check, :boolean
    add_column :source_categories, :generic_details, :string
  end
end
