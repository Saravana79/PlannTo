class CreateUserImages < ActiveRecord::Migration
  def change
    create_table :user_images do |t|
      t.has_attached_file :uploaded_image
      t.timestamps
    end
  end
end
