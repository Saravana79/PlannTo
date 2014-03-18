class AddColumnPublishedAtToFeedUrls < ActiveRecord::Migration
  def change
    add_column :feed_urls, :published_at, :datetime
  end
end
