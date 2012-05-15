class CreateUserImages < ActiveRecord::Migration
  def change
    create_table :user_images do |t|
      t.string :image_content_file_name
	  t.string :image_content_content_type
	  t.string :image_content_file_size
      t.string :image_content_updated_at
      t.timestamps
    end
  end
end
