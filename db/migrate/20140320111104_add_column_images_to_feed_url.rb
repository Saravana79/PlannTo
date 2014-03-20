class AddColumnImagesToFeedUrl < ActiveRecord::Migration
  def change
    add_column :feed_urls, :images, :string, :default => ""
  end
end
