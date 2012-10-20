# To change this template, choose Tools | Templates
# and open the template in the editor.

class Manufacturer < Item
  has_many :itemrelationships, :foreign_key => :relateditem_id
  has_many :products, :through => :itemrelationships
  has_many :related_car_groups, :class_name => 'Itemrelationship', :foreign_key => :relateditem_id
  has_many :relate_car_groups, :through => :related_car_groups
  has_many :related_cars, 
    :through => :related_car_groups
  #before_save :add_relation_type

  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 5.0,  :as => :name_ac
    string :name
    string :status
   end

  def show_specification
    has_specificiation = false
  end 

  def show_buytheprice
    has_buytheprice = false
  end 

  def show_models
    has_models = true
  end 

  def items(page_number = 1, is_pagination = false, no_of_car = configatron.no_of_main_item)
    if is_pagination
      get_paginated_items(page_number)
    else
      get_min_the_items(no_of_car)
    end

  end
  
  def add_relation_type
    #self.relationtype = 'Manufacturer'
  end

  private
  
  def get_min_the_items(no_of_car)
    related_items = relate_car_groups.limit(no_of_car)
    if relate_car_groups.blank?
      related_items = related_cars.where(:type => related_cars.first.class.name).limit(no_of_car)
    end
    related_items
  end

  def get_paginated_items(page_number)
    sub_item = relate_car_groups.where(:type => related_cars.first.class.name)
    if relate_car_groups.blank?
      sub_item = related_cars.where(:type => related_cars.first.class.name)
    end
    sub_item.paginate(:page => page_number, :per_page => 10)
  end



end
