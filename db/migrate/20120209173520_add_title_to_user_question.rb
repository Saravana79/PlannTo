class AddTitleToUserQuestion < ActiveRecord::Migration
  def change
    add_column :user_questions, :title, :string
  end
end
