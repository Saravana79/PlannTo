class CreateDealItems < ActiveRecord::Migration
  def change
    create_table :deal_items do |t|
      t.string :deal_id
      t.string :deal_type
      t.string :deal_state
      t.integer :category
      t.string :asin
      t.string :deal_title
      t.datetime :start_time
      t.datetime :end_time
      t.string :list_price
      t.string :deal_price
      t.string :discount
      t.string :url
      t.string :image_url
      t.string :browse_node_id1
      t.string :sub_category_path1
      t.string :browse_node_id2
      t.string :sub_category_path2
      t.datetime :last_updated_at
      t.timestamps
    end
  end
end
