class Adduserstoall < ActiveRecord::Migration
  TABLES = [:items, :itemtypes, :attributes, :attribute_values, :reviews, :pros, :cons, :best_uses, :debates, :comments]
  
  def up
    TABLES.each do |t|
      add_column t, :created_by, :integer
      add_column t, :updated_by, :integer
      add_column t, :creator_ip, :string
      add_column t, :updater_ip, :string
    end
  end

  def down
    TABLES.each do |t|
      remove_column t, :created_by, :integer
      remove_column t, :updated_by, :integer
      remove_column t, :creator_ip, :string
      remove_column t, :updater_ip, :string
    end
  end
end
