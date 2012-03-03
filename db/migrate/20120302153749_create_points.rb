class CreatePoints < ActiveRecord::Migration
  def change
    create_table :points do |t|
      t.integer :user_id
      t.integer :object_id
      t.string :object_type
      t.string :reason
      t.integer :points

      t.timestamps
    end
  end
end
