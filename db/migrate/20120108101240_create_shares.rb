class CreateShares < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.string :url
      t.string :title
      t.string :description
      t.string :thumbnail
      t.string :youtube
      t.string :user_description
      t.references :item

      t.timestamps
    end
    add_index :shares, :item_id
  end
end
