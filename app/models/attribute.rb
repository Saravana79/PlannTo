class Attribute < ActiveRecord::Base

  TEXT = "Text"
  BOOLEAN = "Boolean"
  NUMERIC = "Numeric"
  
  has_many :attribute_values
  has_many :items, :through => :attribute_values
  has_many :search_display_attributes, :class_name => "SearchAttribute"

  has_one :attribute_comparison_list
  has_many :item_specification_summary_lists 


  #belongs_to :user, :foreign_key => 'created_by'  
end
