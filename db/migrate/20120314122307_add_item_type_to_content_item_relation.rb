class AddItemTypeToContentItemRelation < ActiveRecord::Migration
  def change
    add_column :content_item_relations, :itemtype, :string
  end
end
