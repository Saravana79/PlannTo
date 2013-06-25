class AttributeValue < ActiveRecord::Base
  #cache_records :store => :local, :key => "attributevalues", :index => [:item_id],:request_cache => true

  belongs_to :attribute
  belongs_to :item
  belongs_to :user, :foreign_key => 'created_by'

  def proorcon
  	key = "nothing"
  	self.attribute.item_specification_summary_lists.each do |a|
  		case a.condition
  		when "Not Equal"
	  		key = {key: a.proorcon, description: a.description} if self.value != a.value1
	  	when "Lesser"
	  		key = {key: a.proorcon, description: a.description} if self.value.to_f < a.value1.to_f
	  	when "Greater"
	  		key = {key: a.proorcon, description: a.description} if self.value.to_f > a.value1.to_f
	  	when "Equal"
	  		key = {key: a.proorcon, description: a.description} if self.value = a.value1

	  	when "Between"
	  		key = {key: a.proorcon, description: a.description} if self.value.to_f > a.value1.to_f && self.value.to_f < a.value2.to_f
	  	
  		end
  		
  	end
  	key
  end
end
