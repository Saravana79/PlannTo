class Attribute < ActiveRecord::Base
  has_many :attribute_values
  has_many :items, :through => :attribute_values
  has_many :search_display_attributes, :class_name => "SearchAttribute"

  #belongs_to :user, :foreign_key => 'created_by'
  
end
