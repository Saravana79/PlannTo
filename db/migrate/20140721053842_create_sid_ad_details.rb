class CreateSidAdDetails < ActiveRecord::Migration
  def change
    create_table :sid_ad_details do |t|
      t.integer :sid
      t.integer :impressions
      t.integer :clicks
      t.float :ectr
      t.integer :orders
      t.string :sample_url
      t.string :domain
      t.string :size
      t.integer :position
      t.timestamps
    end
  end
end
