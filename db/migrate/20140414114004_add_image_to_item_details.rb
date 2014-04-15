class AddImageToItemDetails < ActiveRecord::Migration
  def change
    add_column :itemdetails, :Image, :string
  end
end
