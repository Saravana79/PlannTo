class CreateClicks < ActiveRecord::Migration
  def change
    create_table :clicks do |t|
      t.integer :impression_id
      t.string :click_url
      t.string :hosted_site_url
      t.datetime :timestamp
      t.integer :item_id
      t.integer :user_id
      t.string :ipaddress

      t.timestamps
    end
  end
end
