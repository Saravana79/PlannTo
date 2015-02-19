class AddColumnCreatedTypeAndCreatedByToFeedUrl < ActiveRecord::Migration
  def change
    add_column :feed_urls, :created_by, :integer
    add_column :feed_urls, :created_type, :string
  end
end
