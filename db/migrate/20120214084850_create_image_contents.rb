class CreateImageContents < ActiveRecord::Migration
  def up
    create_table :image_contents do |t|
      t.string :image_content_file_name
	  t.string :image_content_content_type
      t.string :image_content_file_size
      t.string :image_content_updated_at
    end
    create_citier_view(ImageContent)
  end

  def down
     drop_table :image_contents
     drop_citier_view(ImageContent)
  end
end
