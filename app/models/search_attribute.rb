class SearchAttribute < ActiveRecord::Base

  CLICK = "Click"
  
  self.table_name = "search_display_attributes"
  # attr_accessor_with_default :primary_key, 'id'
  attr_writer :primary_key

  def primary_key
    @primary_key || 'id'
  end

  scope :by_itemtype, lambda { |type|
    where("itemtype_id =?", type)
  }
  # has_many :attributes_relationships, :class_name => "AttributesRelationships"
  belongs_to :attribute
  belongs_to :itemtype
end
