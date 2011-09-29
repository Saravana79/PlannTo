class CreateAttributes < ActiveRecord::Migration
  def change
    create_table :attributes do |t|
      t.string   :name, :limit => 500, :null => false
      t.string   :attribute_type, :limit => 100, :null => false
      t.string   :unit_of_measure,:limit => 100
      t.string   :category_name, :limit=> 50
      t.integer  :priority

      t.timestamps
    end
  end
end
