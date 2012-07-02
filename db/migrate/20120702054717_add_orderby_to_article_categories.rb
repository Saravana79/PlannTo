class AddOrderbyToArticleCategories < ActiveRecord::Migration
  def change
    add_column :article_categories, :orderby, :integer
  end
end
