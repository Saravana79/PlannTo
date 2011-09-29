class CreateItemtypes < ActiveRecord::Migration
  def change
    create_table :itemtypes do |t|
      t.string :itemtype, :null => false, :limit => 2000
      t.string :description, :null=> false, :limit => 5000
      t.timestamps
    end
  end
end