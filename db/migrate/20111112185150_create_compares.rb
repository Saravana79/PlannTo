class CreateCompares < ActiveRecord::Migration
  def change
    create_table :compares do |t|
      t.integer :compare_id
      t.string :compare_type
      t.string :session_id

      t.timestamps
    end
  end
end
