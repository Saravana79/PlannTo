class CreateContentPhotos < ActiveRecord::Migration
 def self.up
    create_table :content_photos do |t|
      t.has_attached_file :photo
      t.integer :content_id
    end
  end

  def self.down
    drop_attached_file :content_photos, :photo
  end
end
