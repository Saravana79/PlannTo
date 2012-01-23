class SearchAttribute < ActiveRecord::Base

  CLICK = "Click"
  
  set_table_name "search_display_attributes"
  attr_accessor_with_default :primary_key, 'id'

  scope :by_itemtype, lambda { |type|
    where("itemtype_id =?", type)
  }
  # has_many :attributes_relationships, :class_name => "AttributesRelationships"
  belongs_to :attribute
  belongs_to :itemtype
end
