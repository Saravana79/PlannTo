class Itemtype < ActiveRecord::Base
  CAR = "Car"
  has_many :items
  has_many :attributes_relationships
  has_many :article_categories
  has_many :contents

  def self.get_followable_types(item_type)
    case item_type
      when 'Products'
        return Item::TYPES
      else
        return [item_type]
    end
  end
  
  def self.get_item_type_from_params(item_type) 
    case item_type
      when 'Cars'
        return 'Car'
      when 'Mobile'
        return 'Mobile'
      when 'Camera'
        return 'Camera'
      when 'Cycle'
        return 'Cycle'
      when 'Tablet'
        return 'Tablet'
      when 'Bike'
        return 'Bike'
      else
        return 'Car'
    end
  end

end
