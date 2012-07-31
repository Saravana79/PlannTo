class AddUrlToContentPhoto < ActiveRecord::Migration
  def change
    add_column :content_photos,:url, :string
  end
end
