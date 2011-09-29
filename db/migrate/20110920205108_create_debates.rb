class CreateDebates < ActiveRecord::Migration
  def change
    create_table :debates do |t|
      t.integer   :item_id , :null => false
      t.integer   :review_id, :null => false
      t.integer   :argument_id, :null => false
      t.string    :argument_type, :null =>false
      t.timestamps
    end
  end
end
