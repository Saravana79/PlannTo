class RemoveColumnUploadImageToAdvertisements < ActiveRecord::Migration
  def up
    remove_attachment :advertisements, :upload_image
    remove_column :advertisements, :ad_size
  end

  def down
    add_attachment :advertisements, :upload_image
    add_column :advertisements, :ad_size, :string
  end
end
