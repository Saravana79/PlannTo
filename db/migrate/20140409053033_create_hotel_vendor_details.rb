class CreateHotelVendorDetails < ActiveRecord::Migration
  def change
    create_table :hotel_vendor_details do |t|
      t.integer :item_id
      t.string :vendor_id
      t.integer :reference_id
      t.float :price
      t.string :url

      t.timestamps
    end
  end
end
