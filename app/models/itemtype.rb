class Itemtype < ActiveRecord::Base
  CAR = "Car"
  has_many :items
  has_many :attributes_relationships
  has_many :article_categories
  has_many :contents

  def self.get_followable_types(item_type)
    case item_type
      when 'Car'
        return ['Car', 'Manufacturer', 'CarGroup']
      when 'Mobile'
        return ['Mobile']
      else
        return ['Car', 'Manufacturer', 'CarGroup']
    end
  end
end
