class CreateItemDetailOtherMappings < ActiveRecord::Migration
  def change
    create_table :item_detail_other_mappings do |t|
      t.integer :item_detail_other_id
      t.integer :item_id
    end
  end
end
