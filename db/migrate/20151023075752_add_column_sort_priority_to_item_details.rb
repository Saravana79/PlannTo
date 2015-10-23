class AddColumnSortPriorityToItemDetails < ActiveRecord::Migration
  def change
    add_column :itemdetails, :sort_priority, :integer, :default => 1
  end
end
