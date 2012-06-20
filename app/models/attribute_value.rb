class AttributeValue < ActiveRecord::Base
  #cache_records :store => :local, :key => "attributevalues", :index => [:item_id],:request_cache => true

  belongs_to :attribute
  belongs_to :item
  belongs_to :user, :foreign_key => 'created_by'
end
