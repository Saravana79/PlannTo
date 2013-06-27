class AddSortorderToAttributeComparisionLists < ActiveRecord::Migration
  def change
    add_column :attribute_comparison_lists, :sortorder, :integer
  end
end
