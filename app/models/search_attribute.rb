class SearchAttribute < ActiveRecord::Base
  set_table_name "search_display_attributes"
  attr_accessor_with_default :primary_key, 'id'
 # has_many :attributes_relationships, :class_name => "AttributesRelationships"
 belongs_to :attribute
 belongs_to :itemtype
end
