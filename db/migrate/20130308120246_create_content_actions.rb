class CreateContentActions < ActiveRecord::Migration
  def change
    create_table :content_actions do |t|
      t.integer :action_done_by
      t.string   :action
      t.text     :reason
      t.integer :content_id
      t.datetime :time
      t.boolean   :sent_mail,:default => false
      t.timestamps
    end
  end
end
