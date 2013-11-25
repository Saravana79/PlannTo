class Addvendoridtoorderhistories < ActiveRecord::Migration
  def up
  end

  def change
  	add_column :order_histories,:vendor_ids,:int
  	add_column :order_histories,:order_status,:string
  	add_column :order_histories,:payment_status,:string
  	add_column :order_histories,:item_id,:int
  	add_column :order_histories,:item_name,:string
  	add_column :order_histories,:product_price,:string
  	add_column :impression_missings,:vendor_id,:int
  	add_column :impression_missings,:status,:int
  	
  end

  def down
  end
end
