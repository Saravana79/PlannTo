class AddCoulmnsArticleCategoryAndArticleItemIdsToFeedUrls < ActiveRecord::Migration
  def change
    add_column :feed_urls, :article_category, :string
    add_column :feed_urls, :article_item_ids, :string
  end
end
