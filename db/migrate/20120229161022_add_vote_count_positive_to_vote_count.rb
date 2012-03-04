class AddVoteCountPositiveToVoteCount < ActiveRecord::Migration
  def change
    add_column :vote_counts, :vote_count_positive, :integer
    add_column :vote_counts, :vote_count_negative, :integer
  end
end
