# To change this template, choose Tools | Templates
# and open the template in the editor.

class Accessory < Item
  
  has_many :item_relationships, :foreign_key => :relateditem_id
  has_many :products,
           :through => :item_relationships


end
