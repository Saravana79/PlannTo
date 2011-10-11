# To change this template, choose Tools | Templates
# and open the template in the editor.

class Manufacturer < Item
  has_many :itemrelationships, :foreign_key => :relateditem_id
  has_many :products,
    :through => :itemrelationships

  before_save :add_relation_type

  searchable :auto_index => true, :auto_remove => true  do
    text :name, :boost => 4.0,  :as => :name_ac
  end

  def add_relation_type
    self.relationtype = 'Manufacturer'

  end

end
