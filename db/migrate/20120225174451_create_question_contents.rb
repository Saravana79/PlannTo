class CreateQuestionContents < ActiveRecord::Migration
  def up
    create_table :question_contents do |t|
      t.string    :format,      :limit => 1
      t.boolean   :is_answered, :default => false
    end
    create_citier_view(QuestionContent)
  end

  def down
  	drop_table :question_contents
  	drop_citier_view(QuestionContent)
  end	

end


