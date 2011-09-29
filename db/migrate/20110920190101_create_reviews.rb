class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.string     :title, :limit => 200
      t.string     :description, :limit => 5000
      t.integer    :rating
      t.boolean    :recommend_this
      t.integer    :item_id

      t.timestamps
    end
  end
end
