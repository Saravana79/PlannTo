class CreateFeedUrls < ActiveRecord::Migration
  def change
    create_table :feed_urls do |t|
      t.integer :feed_id
      t.string :url
      t.string :title
      t.integer :status
      t.string :source
      t.string :category
      t.text :summary
      t.timestamps
    end
  end
end
