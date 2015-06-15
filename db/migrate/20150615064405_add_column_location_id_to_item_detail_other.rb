class AddColumnLocationIdToItemDetailOther < ActiveRecord::Migration
  def change
    add_column :item_detail_others, :location_id, :integer
  end
end
