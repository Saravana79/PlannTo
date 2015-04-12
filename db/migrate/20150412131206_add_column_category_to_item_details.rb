class AddColumnCategoryToItemDetails < ActiveRecord::Migration
  def change
    add_column :itemdetails, :category, :string
  end
end
