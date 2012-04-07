class AddUpdateToView < ActiveRecord::Migration
  def change
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
