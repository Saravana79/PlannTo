class CreateViewForThumbnail < ActiveRecord::Migration
  def up
    drop_citier_view(ReviewContent)
    create_citier_view(ReviewContent)
    drop_citier_view(QuestionContent)
    create_citier_view(QuestionContent)
  end

  def down
  end
end
