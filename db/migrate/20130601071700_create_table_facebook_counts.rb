class CreateTableFacebookCounts < ActiveRecord::Migration
  def change
    create_table :facebook_counts do |t|
      t.integer :content_id
      t.integer  :share_count
      t.integer  :like_count
      t.integer :comment_count
      t.integer :total_count
      t.integer :click_count
      t.timestamps
    end
  end
end    


