class AddColumnField1ToImageContents < ActiveRecord::Migration
  def change
    drop_citier_view(ImageContent)
    add_column :image_contents, :parent_url, :string
    add_column :image_contents, :url, :string
    add_column :image_contents, :field1, :string
    add_column :image_contents, :field2, :string
    add_column :image_contents, :field3, :string
    add_column :image_contents, :field4, :string
    create_citier_view(ImageContent)
  end
end
