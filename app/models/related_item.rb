class RelatedItem < ActiveRecord::Base
  belongs_to :parent_item,:class_name => "Item", :foreign_key => "item_id"
end
