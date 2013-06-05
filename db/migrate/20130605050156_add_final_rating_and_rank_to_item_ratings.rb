class AddFinalRatingAndRankToItemRatings < ActiveRecord::Migration
  def change
    add_column :item_ratings, :final_rating, :decimal
    add_column :item_ratings, :rank, :int
  end
end
