class CreateRecommendations < ActiveRecord::Migration
  def change
    create_table :recommendations do |t|
      t.integer :user_answer_id
      t.integer :item_id

      t.timestamps
    end
  end
end
