class AddCommentCountToVoteCount < ActiveRecord::Migration
  def change
    add_column :vote_counts, :comment_count, :integer
  end
end
