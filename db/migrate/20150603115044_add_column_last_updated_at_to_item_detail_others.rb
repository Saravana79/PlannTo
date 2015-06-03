class AddColumnLastUpdatedAtToItemDetailOthers < ActiveRecord::Migration
  def change
    remove_column :item_detail_others, :last_modified_date
    add_column :item_detail_others, :last_updated_at, :datetime
  end
end
