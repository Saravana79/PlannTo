class Itemimage < ActiveRecord::Base
  def image_url(imagetype = :medium)
      type = Item.find(self.ItemId).type
      if(!"#{self.ImageURL}".blank?)
        if(imagetype == :medium)
             configatron.root_image_url + type.downcase + '/medium/' + "#{self.ImageURL}"
        else
             configatron.root_image_url + type.downcase + '/small/' + "#{self.ImageURL}"
        end
      end   
  end
end
