class RemoveRatingField < ActiveRecord::Migration
  def up
    remove_column :article_contents, :rating
    drop_citier_view(ArticleContent)
     create_citier_view(ArticleContent)
     drop_citier_view(ImageContent)
    create_citier_view(ImageContent)
    drop_citier_view(ReviewContent)
    create_citier_view(ReviewContent)
    drop_citier_view(QuestionContent)
    create_citier_view(QuestionContent)
    drop_citier_view(AnswerContent)
    create_citier_view(AnswerContent)
  end

  def down
  end
end
