class CreateCompares < ActiveRecord::Migration
  def change
    create_table :compares do |t|
      t.integer :product_id
      t.integer :item_id

      t.timestamps
    end
  end
end
