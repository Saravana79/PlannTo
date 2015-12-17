class ItemContentsRelationsCache < ActiveRecord::Base
  self.table_name = :item_contents_relations_cache
  belongs_to :content
  belongs_to :item
end
