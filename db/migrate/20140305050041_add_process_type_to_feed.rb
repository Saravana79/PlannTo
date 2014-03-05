class AddProcessTypeToFeed < ActiveRecord::Migration
  def change
    remove_column :feed_urls, :process_type
    add_column :feeds, :process_type, :string
    add_column :feeds, :process_value, :string
  end
end
