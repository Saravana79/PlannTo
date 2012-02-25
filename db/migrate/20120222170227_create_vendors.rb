class CreateVendors < ActiveRecord::Migration
  def change
    create_table :vendors do |t|

      t.timestamps
    end
  end
end
