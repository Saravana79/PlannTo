class AddImpressionDetailsToOrderHistory < ActiveRecord::Migration
  def change
    add_column :order_histories, :impression_time, :datetime
    add_column :order_histories, :domain, :string
    add_column :order_histories, :impression_cost, :float
  end
end
