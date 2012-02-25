class CreateItemdetails < ActiveRecord::Migration
  def change
    create_table :itemdetails do |t|
      t.integer		:shippingunit
      t.integer :guarantee
      t.integer :guaranteeunit
      t.boolean		:iscashondeliveryavailable
      t.integer :saveonpercentage
      t.integer :savepercentage
      t.integer :cashback
      t.boolean :isemiavailable
      t.string :site
      t.string		:shipping
      t.integer 	:item_details_id
      t.integer 	:itemid
      t.integer :status
      t.timestamps
    end
  end
end
