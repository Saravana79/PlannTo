class AddColumnArticleContentIdToFeedUrls < ActiveRecord::Migration
  def change
    add_column :feed_urls, :article_content_id, :integer
  end
end
