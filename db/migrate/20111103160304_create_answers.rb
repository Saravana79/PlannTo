class CreateAnswers < ActiveRecord::Migration
  def change
    create_table :answers do |t|
      t.references :question
      t.text       :content
      t.string     :format,      :limit => 1
      t.boolean    :mark_as_answer, :default => false
      t.integer    :created_by
      t.integer    :updated_by
      t.string     :creator_ip
      t.string     :updator_ip
      t.timestamps
    end
  end
end
