class AddColumnMissingCountToFeedUrl < ActiveRecord::Migration
  def change
    add_column :feed_urls, :missing_count, :integer, :default => 0
  end
end
