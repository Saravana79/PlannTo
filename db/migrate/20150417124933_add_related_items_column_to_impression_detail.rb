class AddRelatedItemsColumnToImpressionDetail < ActiveRecord::Migration
  def change
    add_column :impression_details, :having_related_items, :boolean, :default => false
  end
end
