class Attribute < ActiveRecord::Base

  TEXT = "Text"
  BOOLEAN = "Boolean"
  NUMERIC = "Numeric"
  
  has_many :attribute_values
  has_many :items, :through => :attribute_values
  has_many :search_display_attributes, :class_name => "SearchAttribute"

  #belongs_to :user, :foreign_key => 'created_by'
  
end
