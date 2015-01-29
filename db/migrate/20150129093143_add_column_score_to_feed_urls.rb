class AddColumnScoreToFeedUrls < ActiveRecord::Migration
  def change
    add_column :feed_urls, :score, :decimal, :precision => 8, :scale => 2
  end
end
