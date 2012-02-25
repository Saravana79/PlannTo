class CreateReviewContents < ActiveRecord::Migration
  def up
    create_table :review_contents do |t|
      t.integer    :rating
      t.boolean    :recommend_this
      t.string	   :pros
      t.string	   :cons
    end
    create_citier_view(ReviewContent)
  end

  def down
    drop_table :review_contents
    drop_citier_view(ReviewContent) 
  end
end
