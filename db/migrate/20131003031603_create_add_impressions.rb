class CreateAddImpressions < ActiveRecord::Migration
  def change
    create_table :add_impressions do |t|
      t.string :advertisement_type
      t.integer :impression_id
      t.integer :item_id
      t.string :hosted_site_url
      t.datetime :impression_time
      t.integer :publisher_id
      t.integer :user_id
      t.string :ip_address

      t.timestamps
    end
  end
end
