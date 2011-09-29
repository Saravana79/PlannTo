class Itemrelationship < ActiveRecord::Base
  belongs_to :product#, :foreign_key => :item_id
  belongs_to :manufacturer, :foreign_key => :relateditem_id
  belongs_to :accessory, :foreign_key => :relateditem_id
  belongs_to :car #, :foreign_key => :item_id
  belongs_to :relatedcars, :class_name => 'Car', :foreign_key => :relateditem_id
end

#  belongs_to :item
#  belongs_to :relateditem, :class_name  => 'Item'