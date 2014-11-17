class AddColumnAdditionalDetailsToItemDetails < ActiveRecord::Migration
  def change
    add_column :itemdetails, :additional_details, :string
  end
end
