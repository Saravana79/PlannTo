class ItemAttributeTagRelation < ActiveRecord::Base
  belongs_to :attribute
  belongs_to :attribute_tag, :foreign_key => 'item_id'
  belongs_to :user, :foreign_key => 'created_by'
end
