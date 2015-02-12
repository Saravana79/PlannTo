class AddColumnsStatusToCategoryItemDetails < ActiveRecord::Migration
  def change
    add_column :category_item_details, :status, :boolean, :default => true
  end
end
