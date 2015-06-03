class AddColumnItemtypeIdToItemDetailOthers < ActiveRecord::Migration
  def change
    add_column :item_detail_others, :itemtype_id, :integer
  end
end
