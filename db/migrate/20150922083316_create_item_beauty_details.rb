class CreateItemBeautyDetails < ActiveRecord::Migration
  def change
    create_table :item_beauty_details do |t|
      t.text :name
      t.string :url
      t.decimal :price
      t.integer :status
      t.datetime :last_verified_date
      t.boolean :is_error, :default => false
      t.string :error_details
      t.string :offer
      t.string :image
      t.decimal :mrp_price
      t.integer :cashback
      t.string :site
      t.string :additional_details
      t.string :color
      t.string :description
      t.string :category
      t.string :gender
      t.timestamps
    end
  end
end
