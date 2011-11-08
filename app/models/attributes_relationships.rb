class AttributesRelationships < ActiveRecord::Base
  set_table_name "attributesrelationships"
  belongs_to :attribute

  has_many :search_display_attributes, :primary_key => "attribute_id", :foreign_key => "attribute_id", :class_name => "SearchAttribute"
end
