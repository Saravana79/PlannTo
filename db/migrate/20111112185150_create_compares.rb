class CreateCompares < ActiveRecord::Migration
  def change
    create_table :compares do |t|
      t.integer :comparable_id
      t.string :comparable_type
      t.string :session_id

      t.timestamps
    end
  end
end
