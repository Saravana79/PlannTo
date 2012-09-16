class AddGuideIdsToContent < ActiveRecord::Migration
  def change
    add_column :contents, :content_guide_info_ids, :string
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
end
