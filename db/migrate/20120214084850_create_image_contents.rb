class CreateImageContents < ActiveRecord::Migration
  def up
    create_table :image_contents do |t|
      t.has_attached_file :image_content
    end
    create_citier_view(ImageContent)
  end

  def down
     drop_table :image_contents
     drop_citier_view(ImageContent)
  end
end
