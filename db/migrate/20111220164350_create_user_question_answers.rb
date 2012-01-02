class CreateUserQuestionAnswers < ActiveRecord::Migration
  def change
    create_table :user_question_answers do |t|
      t.integer :user_question_id
      t.integer :user_answer_id

      t.timestamps
    end
  end
end
