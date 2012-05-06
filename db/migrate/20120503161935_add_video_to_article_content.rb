class AddVideoToArticleContent < ActiveRecord::Migration
  def change
   # drop_citier_view(ArticleContent)
    #add_column :article_contents, :video, :boolean
     create_citier_view(ArticleContent)
  end
end
