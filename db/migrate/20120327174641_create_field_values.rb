class CreateFieldValues < ActiveRecord::Migration
  def change
    create_table :field_values do |t|
      t.integer :id
      t.integer :field_id
      t.string :value

      t.timestamps
    end
  end
end
