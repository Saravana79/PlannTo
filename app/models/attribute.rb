class Attribute < ActiveRecord::Base

  TEXT = "Text"
  BOOLEAN = "Boolean"
  NUMERIC = "Numeric"
  
  has_many :attribute_values
  has_many :items, :through => :attribute_values
  has_many :search_display_attributes, :class_name => "SearchAttribute"

  #belongs_to :user, :foreign_key => 'created_by'

  def lower_search_value(variance)
    value = self.value.to_f - self.value.to_f/variance
    return value.to_i
  end

  def upper_search_value(variance)
    value = self.value.to_f + self.value.to_f/variance
    return value.to_i
  end
  
end
