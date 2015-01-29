class AddColumnScoreToFeedUrls < ActiveRecord::Migration
  def change
    add_column :feed_urls, :score, :decimal
  end
end
