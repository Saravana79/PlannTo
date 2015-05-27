class CreateItemDetailOthers < ActiveRecord::Migration
  def change
    create_table :item_detail_others do |t|
      t.string :title
      t.string :url
      t.float :price
      t.integer :status
      t.string :ad_detail1
      t.string :ad_detail2
      t.string :ad_detail3
      t.string :ad_detail4
      t.date :added_date
      t.date :last_modified_date
      t.timestamps
    end
  end
end
