class Itemrelationship < ActiveRecord::Base
  belongs_to :product#, :foreign_key => :item_id
  belongs_to :manufacturer, :foreign_key => :relateditem_id
  belongs_to :accessory, :foreign_key => :relateditem_id
  belongs_to :car #, :foreign_key => :item_id
  belongs_to :cargroup, :foreign_key => :relateditem_id , :class_name => "CarGroup"
  belongs_to :relate_car_groups, :foreign_key => :item_id , :class_name => "CarGroup"
  belongs_to :related_cars, :foreign_key => :item_id , :class_name => "Item"
  belongs_to :relateditems, :class_name => 'Item', :foreign_key => :relateditem_id
end

#  belongs_to :item
#  belongs_to :relateditem, :class_name  => 'Item'