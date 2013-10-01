class CreatePublisherVendors < ActiveRecord::Migration
  def change
    create_table :publisher_vendors do |t|
      t.integer :publisher_id
      t.integer :vendor_id
      t.string :affliateid
      t.string :trackid

      t.timestamps
    end
  end
end
