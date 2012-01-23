class AddReputationToUser < ActiveRecord::Migration
  def change
    add_column :users, :reputation, :integer, :null => false, :default => 0
  end
end
