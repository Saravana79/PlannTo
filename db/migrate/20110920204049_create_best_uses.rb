class CreateBestUses < ActiveRecord::Migration
  def change
    create_table :best_uses do |t|
      t.string    :title, :limit => 50, :null => false
      t.integer  :item_id, :null => false
      t.timestamps
    end
  end
end
