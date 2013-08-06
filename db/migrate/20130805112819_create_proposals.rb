class CreateProposals < ActiveRecord::Migration
  def change
    create_table :proposals do |t|
      t.integer :item_id
      t.integer :buying_plan_id
      t.date :expiry_date
      t.float :item_price
      t.string :delivery_period
      t.float :shipping_cost
      t.string :color
      t.text :comments

      t.timestamps
    end
  end
end
