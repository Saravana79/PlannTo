class AddItemtypeIdInItemDetailOtherMappings < ActiveRecord::Migration
  def up
    add_column :item_detail_other_mappings, :itemtype_id, :integer
  end

  def down
    remove_column :item_detail_other_mappings, :itemtype_id
  end
end
