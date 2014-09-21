class AddColumnPaginationAndPaginationTypeToSourceCategory < ActiveRecord::Migration
  def change
    add_column :source_categories, :is_having_pagination, :boolean, :default => false
    add_column :source_categories, :pattern, :string
  end
end
