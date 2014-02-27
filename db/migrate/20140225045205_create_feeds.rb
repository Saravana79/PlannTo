class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
      t.string :url
      t.string :title
      t.string :category
      t.datetime :last_updated_at
      t.integer :created_by
      t.timestamps
    end
  end
end
