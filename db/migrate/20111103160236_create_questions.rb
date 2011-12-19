class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.string    :title
      t.text      :description
      t.string    :format,      :limit => 1
      t.boolean   :is_answered, :default => false
      t.integer   :created_by
      t.integer   :updated_by
      t.string    :creator_ip
      t.string    :updator_ip
      t.timestamps
    end
  end
end
