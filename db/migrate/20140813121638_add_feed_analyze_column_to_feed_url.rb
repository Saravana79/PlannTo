class AddFeedAnalyzeColumnToFeedUrl < ActiveRecord::Migration
  def change
    add_column :feed_urls, :old_default_values, :string
    add_column :feed_urls, :new_default_values, :string
    add_column :feed_urls, :default_status, :boolean
  end
end
