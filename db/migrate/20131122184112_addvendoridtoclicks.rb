class Addvendoridtoclicks < ActiveRecord::Migration
  def up
  end
  def change
  	add_column :clicks,:vendor_id,:int
  end
  def down
  end
end
