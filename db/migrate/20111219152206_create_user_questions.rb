class CreateUserQuestions < ActiveRecord::Migration
  def change
    create_table :user_questions do |t|
      t.integer :itemtype_id
      t.integer :user_id
      t.text :question

      t.timestamps
    end
  end
end
