class AddDescriptionToItemDetails < ActiveRecord::Migration
  def change
    add_column :itemdetails, :description, :string
  end
end
