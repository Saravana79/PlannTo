class CreateClickDetails < ActiveRecord::Migration
  def change
    create_table :click_details do |t|
      t.uuid :click_id
      t.integer :tagging
      t.integer :retargeting
      t.integer :pre_appearance_count
      t.string :additional_details
    end
  end
end
