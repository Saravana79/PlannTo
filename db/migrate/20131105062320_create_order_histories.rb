class CreateOrderHistories < ActiveRecord::Migration
  def change
    create_table :order_histories do |t|
      t.datetime :order_date
      t.integer :no_of_orders
      t.float :total_revenue
      t.integer :publisher_id

      t.timestamps
    end
  end
end
