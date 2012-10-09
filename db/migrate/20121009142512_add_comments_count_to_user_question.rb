class AddCommentsCountToUserQuestion < ActiveRecord::Migration
  def change
    add_column :user_questions, :no_of_votes, :integer
    add_column :user_questions, :positive_votes, :integer
    add_column :user_questions, :negative_votes, :integer
    add_column :user_questions, :total_votes, :integer
    add_column :user_questions, :comments_count, :integer
  end
end
