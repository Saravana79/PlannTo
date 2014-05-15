class AddImageAndMrppriceToItemdetails < ActiveRecord::Migration
  def change
    add_column :itemdetails, :mrpprice, :decimal
  end
end
