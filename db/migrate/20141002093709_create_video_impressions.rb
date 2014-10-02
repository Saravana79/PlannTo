class CreateVideoImpressions < ActiveRecord::Migration
  def change
    create_table :video_impressions do |t|
      t.integer :advertisement_id
      t.string :type
      t.string :ref_url
      t.string :ip_address
      t.string :winning_price
      t.string :sid
      t.string :item_id
      t.datetime :impression_time
      t.timestamps
    end
  end
end
