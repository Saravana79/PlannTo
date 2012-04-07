class AddColumnToArticleContent < ActiveRecord::Migration
  def change
   # drop_table :article_contents
    drop_citier_view(ArticleContent)
    add_column :article_contents, :field1, :string
    add_column :article_contents, :field2, :string
    add_column :article_contents, :field3, :string
    add_column :article_contents, :field4, :string
#      create_table :article_contents do |t|
#      t.string  :url
#      t.string  :thumbnail
#      t.integer :article_category_id
#      t.string :field1
#      t.string :field2
#      t.string :field3
#      t.string :field4
#    end
    create_citier_view(ArticleContent)
  end
end
