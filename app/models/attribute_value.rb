class AttributeValue < ActiveRecord::Base
  #cache_records :store => :local, :key => "attributevalues", :index => [:item_id],:request_cache => true

  belongs_to :attribute
  belongs_to :item
  belongs_to :user, :foreign_key => 'created_by'

  def proorcon
  	key = "nothing"
  	self.attribute.item_specification_summary_lists.each do |a|
      unless(self.value.nil? or self.value.strip.empty?)
    		case a.condition
    		when "Not Equal"
  	  		key = {key: a.proorcon, description: a.description, title: a.title} if self.value.downcase.strip != a.value1.downcase.strip
  	  	when "Lesser"
  	  		key = {key: a.proorcon, description: a.description , title: a.title} if self.value.to_f < a.value1.to_f
  	  	when "Greater"
  	  		key = {key: a.proorcon, description: a.description, title: a.title} if self.value.to_f > a.value1.to_f
  	  	when "Equal"
          if(a.value1 == "****")            
              key = {key: a.proorcon, description: a.description, title: a.title}       
          else
             key = {key: a.proorcon, description: a.description, title: a.title} if self.value.downcase.strip == a.value1.downcase.strip          
          end
        when "Contains"
             key = {key: a.proorcon, description: a.description, title: a.title} if self.value.downcase.include? a.value1.downcase.strip                    
  	  	when "Between"
  	  		key = {key: a.proorcon, description: a.description, title: a.title} if self.value.to_f > a.value1.to_f && self.value.to_f < a.value2.to_f
  	  	
    		end
      else
        if(a.condition == "Not Equal" and a.value == "****") 
            key = {key: a.proorcon, description: a.description, title: a.title}
        end
  		end
  	end
  	key
  end
end
