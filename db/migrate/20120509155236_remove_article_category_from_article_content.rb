class RemoveArticleCategoryFromArticleContent < ActiveRecord::Migration
  def up
    remove_column :article_contents, :article_category_id
  end

  def down
  end
end
