class ChangeColumnTypeDefaultStatusToFeedUrls < ActiveRecord::Migration
  def up
    change_column :feed_urls, :default_status, :integer
  end

  def down
    change_column :feed_urls, :default_status, :boolean
  end
end
