class AddFieldsToUserAnswer < ActiveRecord::Migration
  def change
    add_column :user_answers, :no_of_votes, :integer
    add_column :user_answers, :positive_votes, :integer
    add_column :user_answers, :negative_votes, :integer
    add_column :user_answers, :total_votes, :integer
    add_column :user_answers, :comments_count, :integer
  end
end
