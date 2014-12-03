class Itemrelationship < ActiveRecord::Base
  belongs_to :product#, :foreign_key => :item_id
  belongs_to :manufacturer, :foreign_key => :relateditem_id
  belongs_to :accessory, :foreign_key => :relateditem_id
  belongs_to :car #, :foreign_key => :item_id
  belongs_to :cargroup, :foreign_key => :relateditem_id , :class_name => "CarGroup"
  belongs_to :relate_car_groups, :foreign_key => :item_id , :class_name => "CarGroup"
  belongs_to :related_cars, :foreign_key => :item_id , :class_name => "Item"
  belongs_to :items, :foreign_key => :item_id , :class_name => "Item"
  belongs_to :relateditems, :class_name => 'Item', :foreign_key => :relateditem_id

  belongs_to :states, :class_name => 'State', :foreign_key => :item_id
  belongs_to :country, :class_name => 'Country', :foreign_key => :relateditem_id

  belongs_to :cities, :class_name => 'City', :foreign_key => :item_id
  belongs_to :related_state, :class_name => 'State', :foreign_key => :relateditem_id

  belongs_to :hotels, :class_name => 'Hotel', :foreign_key => :item_id
  belongs_to :related_city, :class_name => 'City', :foreign_key => :relateditem_id


  belongs_to :parent, :foreign_key => :relateditem_id, :class_name => "Beauty"
end

#  belongs_to :item
#  belongs_to :relateditem, :class_name  => 'Item'