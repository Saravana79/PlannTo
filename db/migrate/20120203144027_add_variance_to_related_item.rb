class AddVarianceToRelatedItem < ActiveRecord::Migration
  def change
    add_column :related_items, :variance, :string
  end
end
