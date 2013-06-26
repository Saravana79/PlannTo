class ItemSpecificationSummaryList < ActiveRecord::Base
	belongs_to :item_type
	belongs_to :attribute

	attr_protected :sortorder

  def procon
  	key = "nothing"
  	logger.info "======================#{self.attributes}"
  	# self.attribute.attribute_values.find_by_item_id()
      unless(self['value'].nil? or self['value'].strip.empty?)
    	case condition
    	when "Not Equal"
          if(value1 != "****")
  	  		   key = {key: proorcon, description: description, title: title} if self['value'].downcase.strip != value1.downcase.strip
          end
          key
  	  	when "Lesser"
  	  		key = {key: proorcon, description: description , title: title} if self['value'].to_f < value1.to_f
  	  	when "Greater"
  	  		key = {key: proorcon, description: description, title: title} if self['value'].to_f > value1.to_f
  	  	when "Equal"
          if(value1 == "****")            
              key = {key: proorcon, description: description, title: title}       
          else
             key = {key: proorcon, description: description, title: title} if self['value'].downcase.strip == value1.downcase.strip          
          end
        when "Contains"
             key = {key: proorcon, description: description, title: title} if self['value'].downcase.include? value1.downcase.strip                    
  	  	when "Between"
  	  		key = {key: proorcon, description: description, title: title} if self['value'].to_f < value1.to_f && self['value'].to_f > value2.to_f
  	  	
    		end
      else
        if(condition == "Not Equal" and value1 == "****") 
            key = {key: proorcon, description: description, title: title}
        end
        key
  		end
  		logger.info "======================#{key}"
  		key
  	end
  	
  end
