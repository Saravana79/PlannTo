class CreateUserActivities < ActiveRecord::Migration
  def change
    create_table :user_activities do |t|
      t.integer :user_id
      t.integer :related_id
      t.string :related_activity
      t.string :related_activity_type
      t.datetime :time

      t.timestamps
    end
  end
end
