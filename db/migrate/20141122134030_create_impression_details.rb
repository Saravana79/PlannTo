class CreateImpressionDetails < ActiveRecord::Migration
  def change
    create_table :impression_details do |t|
      t.uuid :impression_id
      t.integer :tagging
      t.integer :retargeting
      t.integer :pre_appearance_count
      t.string :additional_details
    end
  end
end
