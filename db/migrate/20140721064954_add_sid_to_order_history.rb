class AddSidToOrderHistory < ActiveRecord::Migration
  def change
    add_column :order_histories, :sid, :string
  end
end
