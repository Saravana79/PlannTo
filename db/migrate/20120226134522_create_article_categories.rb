class CreateArticleCategories < ActiveRecord::Migration
  def up
    create_table :article_categories do |t|
      t.string :name, :null => false
      t.integer :itemtype_id, :null => false, :default => 0
      t.timestamps
    end
    ArticleCategory.create(:name => "Review")
    ArticleCategory.create(:name => "Tip")
  end
  
  def down
    drop_table :article_categories
  end
end
