class ContentItemRelation < ActiveRecord::Base
  	belongs_to :item
  	belongs_to :content
  	validates_presence_of :item_id, :content_id
end


