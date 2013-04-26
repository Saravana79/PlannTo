class AddDomainToArticleContents < ActiveRecord::Migration
  def change
    add_column :article_contents,:domain ,:string
    drop_citier_view(ArticleContent)
    create_citier_view(ArticleContent)
  end
end
