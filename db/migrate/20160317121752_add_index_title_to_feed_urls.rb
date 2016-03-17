class AddIndexTitleToFeedUrls < ActiveRecord::Migration
  def change
    add_index :feed_urls, :title
  end
end
