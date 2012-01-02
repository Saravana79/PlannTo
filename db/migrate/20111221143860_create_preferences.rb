class CreatePreferences < ActiveRecord::Migration
  def change
    create_table :preferences do |t|
      t.integer :buying_plan_id
      t.integer :search_display_attribute_id
      t.string :value_1
      t.string :value_2

      t.timestamps
    end
  end
end
