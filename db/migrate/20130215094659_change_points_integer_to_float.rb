class ChangePointsIntegerToFloat < ActiveRecord::Migration
  def self.up
    change_column :points, :points, :float
  end

  def self.down
    change_column :points, :points, :integer
  end
end
