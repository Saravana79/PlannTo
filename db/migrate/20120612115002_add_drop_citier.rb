class AddDropCitier < ActiveRecord::Migration
  def change
    drop_citier_view(ArticleContent)
    create_citier_view(ArticleContent)
  end

end
