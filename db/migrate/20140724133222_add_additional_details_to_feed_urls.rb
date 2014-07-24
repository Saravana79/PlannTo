class AddAdditionalDetailsToFeedUrls < ActiveRecord::Migration
  def change
    add_column :feed_urls, :additional_details, :string
  end
end
