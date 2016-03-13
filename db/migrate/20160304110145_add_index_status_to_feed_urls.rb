class AddIndexStatusToFeedUrls < ActiveRecord::Migration
  def change
    add_index :feed_urls, :status
  end
end
