class CreateItemdetails < ActiveRecord::Migration
  def change
    create_table :itemdetails do |t|

      t.timestamps
    end
  end
end
