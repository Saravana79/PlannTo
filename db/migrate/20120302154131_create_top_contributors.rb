class CreateTopContributors < ActiveRecord::Migration
  def change
    create_table :top_contributors do |t|
      t.integer :user_id
      t.integer :object_id
      t.string :object_type
      t.integer :rank

      t.timestamps
    end
  end
end
