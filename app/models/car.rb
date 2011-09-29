# To change this template, choose Tools | Templates
# and open the template in the editor.

class Car < Product
  has_many :itemrelationships, :foreign_key => :item_id
  has_many :relatedcars,
           :through => :itemrelationships
  acts_as_taggable
#  acts_as_taggable_on :product
  acts_as_commentable
end
