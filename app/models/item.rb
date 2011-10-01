class Item < ActiveRecord::Base
  belongs_to :itemtype
#  has_many :itemrelationships
#  has_many :relateditems, :through => :itemrelationships
#
#  has_many :inverse_itemrelationships, :class_name => 'Itemrelationship', :foreign_key => 'relateditem_id'
#  has_many :inverse_relateditems, :through => :inverse_itemrelationships, :source => :item
##  has_many :inverse_relateditems, :through => :inverse_itemrelationships, :
  
  has_many :groupmembers, :class_name => 'Item'
  belongs_to :group,   :class_name => 'Item', :foreign_key => 'group_id'

  belongs_to :user, :foreign_key => 'created_by'

  has_many :attribute_values, :include => :attribute 
  has_many :reviews
  has_many :pros
  has_many :cons
  has_many :best_uses

  searchable :auto_index => true, :auto_remove => true  do
    text :name, :boost => 4.0,  :as => :name_ac            
  end

end