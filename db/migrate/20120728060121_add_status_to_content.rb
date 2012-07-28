class AddStatusToContent < ActiveRecord::Migration
  def change
   add_column :contents, :status, :integer

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
    
    add_column :comments, :status, :integer
  end
end
