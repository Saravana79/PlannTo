class AddFieldsToContent < ActiveRecord::Migration
  def change
    add_column :contents, :no_of_votes, :integer
    add_column :contents, :positive_votes, :integer
    add_column :contents, :negative_votes, :integer
    add_column :contents, :total_votes, :integer
    add_column :contents, :comments_count, :integer

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
