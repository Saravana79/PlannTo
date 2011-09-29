class CreateCons < ActiveRecord::Migration
  def change
    create_table :cons do |t|
      t.string    :title, :limit => 50, :null => false
      t.integer  :item_id, :null => false
      t.timestamps
    end
  end
end
