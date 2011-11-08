class Itemtype < ActiveRecord::Base
  has_many :items
  has_many :attributes_relationships
end
