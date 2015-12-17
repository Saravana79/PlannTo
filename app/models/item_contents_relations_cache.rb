class ItemContentsRelationsCache < ActiveRecord::Base
  set_table_name :item_contents_relations_cache
  belongs_to :content
  belongs_to :item
end
