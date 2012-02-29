class Itemtype < ActiveRecord::Base
  CAR = "Car"
  has_many :items
  has_many :attributes_relationships
  has_many :article_categories
  has_many :contents
end
