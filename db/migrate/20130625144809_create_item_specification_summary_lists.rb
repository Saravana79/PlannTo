class CreateItemSpecificationSummaryLists < ActiveRecord::Migration
  def change
    create_table :item_specification_summary_lists do |t|
      t.integer :attribute_id
      t.integer :itemtype_id
      t.string :condition
      t.string :value1
      t.string :value2
      t.string :title
      t.string :description
      t.string :proorcon
      t.integer :sortorder
      t.timestamps
    end
  end
end
