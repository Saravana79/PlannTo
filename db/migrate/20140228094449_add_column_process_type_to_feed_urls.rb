class AddColumnProcessTypeToFeedUrls < ActiveRecord::Migration
  def change
    add_column :feed_urls, :process_type, :string
  end
end
