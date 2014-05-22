class AddPrioritiesToFeedsAndFeedUrls < ActiveRecord::Migration
  def change
    add_column :feeds, :priorities, :integer, :default => 3
    add_column :feed_urls, :priorities, :integer, :default => 3
  end
end
