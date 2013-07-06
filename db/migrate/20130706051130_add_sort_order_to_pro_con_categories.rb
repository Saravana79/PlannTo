class AddSortOrderToProConCategories < ActiveRecord::Migration
  def change
    add_column :pro_con_categories, :sort_order, :int
  end
end
