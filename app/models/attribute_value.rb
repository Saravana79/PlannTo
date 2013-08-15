class AttributeValue < ActiveRecord::Base
  #cache_records :store => :local, :key => "attributevalues", :index => [:item_id],:request_cache => true

  belongs_to :attribute
  belongs_to :item
  belongs_to :user, :foreign_key => 'created_by'


  def proorcon
    key = "nothing"
    tempValue = getValue
    self.attribute.item_specification_summary_lists.each do |a|
      unless(tempValue.nil? or tempValue.strip.empty?)
        case a.condition
        when "Not Equal"
          if(a.value1 != "****")
             key = {key: a.proorcon, description: a.description, title: a.title} if tempValue.downcase.strip != a.value1.downcase.strip
          end
        when "Lesser"
          key = {key: a.proorcon, description: a.description , title: a.title} if tempValue.to_f < a.value1.to_f
        when "Greater"
          key = {key: a.proorcon, description: a.description, title: a.title} if tempValue.to_f > a.value1.to_f
        when "Equal"
          if(a.value1 == "****")            
              key = {key: a.proorcon, description: a.description, title: a.title}       
          else
             key = {key: a.proorcon, description: a.description, title: a.title} if tempValue.downcase.strip == a.value1.downcase.strip          
          end
        when "Contains"
             key = {key: a.proorcon, description: a.description, title: a.title} if tempValue.downcase.include? a.value1.downcase.strip                    
        when "Between"
          key = {key: a.proorcon, description: a.description, title: a.title} if tempValue.to_f > a.value1.to_f && tempValue.to_f < a.value2.to_f
        
        end
      else
        if(a.condition == "Not Equal" and a.value1 == "****") 
            key = {key: a.proorcon, description: a.description, title: a.title}
        end
      end
    end
    key
  end 

  def groupbyvalue

    tempValue = getValue
    
  end 

  def getValue
  # this is used for comparison when displaying pros and cons and also in item comparison, some attributes like resolution has value like 1280x800 which is difficult to compare direclty    
  # hence coverting that to a value that can be cmpared.
    if(self.attribute_id == 170)
       if(self.value.include? "/")
         self.value.gsub(" ","").split("/")[1]
       else
        self.value
       end
    elsif(self.attribute_id == 116)
       if(self.value.include? "x" or self.value.include? "*" )
         arrvalue = self.value..gsub(" ","").split(/[*x]/)
         if(arrvalue[0].to_f > arrvalue[1].to_f)
            arrvalue[0]
         else
            arrvalue[1]
         end
       else
        self.value
       end
    elsif(self.attribute_id == 328)
       if(self.value.include? "@")
         self.value.gsub(" ","").split("@")[0]
       else
        self.value
       end
    else
      self.value
    end
  end
end
