class CarGroup < Item   
  has_many :itemrelationships, :foreign_key => :relateditem_id
  has_many :products, :through => :itemrelationships
  has_many :related_car_groups, :class_name => 'Itemrelationship', :foreign_key => :relateditem_id
  has_many :related_cars,   :through => :related_car_groups


searchable :auto_index => true, :auto_remove => true  do
   text :name , :boost => 3.0,  :as => :name_ac do |item|
      item.name.gsub("_","")
    end 
   string :name do |item|
      item.name.gsub("_", " ")
   end 
  string :status
  integer :orderbyid  do |item|
      item.itemtype.orderby
    end
  time :created_at
 end


def items(page_number = 1, is_pagination = false, no_of_car = configatron.no_of_main_item)
  if is_pagination
    related_cars.where(:type => related_cars.first.class.name).paginate(:page => page_number, :per_page => 10)
  else
    related_cars.where(:type => related_cars.first.class.name).limit(no_of_car)
  end
end

def image_url(imagetype = :medium)
      firstcar = related_cars.first
      firstcar.image_url
end

def manu
    related_cars.first.manufacturer
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

end 
