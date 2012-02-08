class Itemtype < ActiveRecord::Base
  CAR = "Car"
  has_many :items
  has_many :attributes_relationships
end
