class ItemRatings < ActiveRecord::Migration
  def self.up
    create_table :item_ratings, :force => true do |t|
      t.decimal  :expert_review_avg_rating , :precision => 8, :scale => 2
      t.integer  :expert_review_count
      t.integer  :expert_review_total_count
      t.decimal  :user_review_avg_rating, :precision => 8, :scale => 2
      t.integer  :user_review_count
      t.integer  :user_review_total_count
      t.decimal  :average_rating, :precision => 8, :scale => 2
      t.integer  :review_count
      t.integer  :review_total_count
      t.integer  :item_id 
      t.timestamps
    end  
    
   
  end

  def self.down
    drop_table :item_ratings
  end
end

