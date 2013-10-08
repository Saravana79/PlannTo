class CreateAdvertisements < ActiveRecord::Migration
  def change
    create_table :advertisements do |t|
      t.string :name
      t.string :ad_size
      t.has_attached_file :upload_image
      t.string :budget
      t.string :bid
      t.float  :cost
      t.string :advertisement_type
      t.datetime :start_date
      t.datetime :end_date
      t.integer :content_id
      t.integer :status,:default => true
      t.timestamps
    end
  end
end


 
