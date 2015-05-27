class AddColumnImageNameToItemDetailOthers < ActiveRecord::Migration
  def change
    add_column :item_detail_others, :image_name, :string
  end
end
