class AddSortorderToAttributeComparisionLists < ActiveRecord::Migration
  def change
    add_column :attribute_comparison_lists, :sort_order, :integer
  end
end
