class CreateAdvDetails < ActiveRecord::Migration
  def change
    create_table :adv_details do |t|
      t.integer :advertisement_id
      t.string :ad_type
      t.string :expanded_type
      t.boolean :expanded, :default => false
      t.boolean :only_flash, :default => false
      t.timestamps
    end
  end
end
