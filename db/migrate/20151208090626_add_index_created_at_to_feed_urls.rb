class AddIndexCreatedAtToFeedUrls < ActiveRecord::Migration
  def change
    add_index :feed_urls, :created_at
  end
end
