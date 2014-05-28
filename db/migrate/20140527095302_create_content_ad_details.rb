class CreateContentAdDetails < ActiveRecord::Migration
  def change
    create_table :content_ad_details do |t|
      t.string :url
      t.integer :impressions
      t.integer :clicks
      t.float :ectr

      t.timestamps
    end
  end
end
