class AttributeValue < ActiveRecord::Base

  belongs_to :attribute
  belongs_to :item
  belongs_to :user, :foreign_key => 'created_by'
end
