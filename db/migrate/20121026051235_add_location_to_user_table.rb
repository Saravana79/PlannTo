class AddLocationToUserTable < ActiveRecord::Migration
  def change
    add_column :users,:location,:string
  end
end
