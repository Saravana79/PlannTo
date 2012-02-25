class CreateVendors < ActiveRecord::Migration
  def change
    create_table :vendors do |t|
      t.string :name
      t.string :baseurl
      t.string :imageurl
      t.timestamps
    end
  end
end
