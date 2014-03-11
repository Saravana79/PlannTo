class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.has_attached_file :avatar
      t.integer :imageable_id
      t.string :imageable_type
      t.string :ad_size
      t.timestamps
    end
  end
end
