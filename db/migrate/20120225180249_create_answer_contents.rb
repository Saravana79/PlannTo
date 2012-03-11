class CreateAnswerContents < ActiveRecord::Migration
  def up
    create_table :answer_contents do |t|
      t.references :question_content
      t.string     :format,      :limit => 1
      t.boolean    :mark_as_answer, :default => false
    end
    create_citier_view(AnswerContent)
  end

  def down
  	drop_table :answer_contents
  	drop_citier_view(AnswerContent)
  end	

end
