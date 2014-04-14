class AddImageToItemDetails < ActiveRecord::Migration
  def change
    add_column :item_details, :Image, :string
  end
end
