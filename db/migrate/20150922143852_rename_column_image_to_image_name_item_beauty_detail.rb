class RenameColumnImageToImageNameItemBeautyDetail < ActiveRecord::Migration
  def up
    rename_column :item_beauty_details, :image, :image_name
  end

  def down
    rename_column :item_beauty_details, :image_name, :image
  end
end
