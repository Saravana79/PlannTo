class AddUidIndexToUsers < ActiveRecord::Migration
  def change
    add_index :users, :uid
  end
end
