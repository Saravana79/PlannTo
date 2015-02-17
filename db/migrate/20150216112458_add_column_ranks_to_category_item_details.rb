class AddColumnRanksToCategoryItemDetails < ActiveRecord::Migration
  def change
    add_column :category_item_details, :rank, :integer
  end
end
