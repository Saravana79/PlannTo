class CreateArticleContents < ActiveRecord::Migration
  def up
    create_table :article_contents do |t|
      t.string  :url
      t.string  :thumbnail
      t.integer :article_category_id
    end
    create_citier_view(ArticleContent)
  end
  
  def down
    drop_table :article_contents
    drop_citier_view(ArticleContent)
  end
end
