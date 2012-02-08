class CarGroup < Manufacturer  

  def car_groups(page_number = 1, is_pagination = false, no_of_car = configatron.no_of_main_item)
    if is_pagination
      related_cars.where(:type => related_cars.first.class.name).paginate(:page => page_number, :per_page => 10)
    else
      related_cars.where(:type => related_cars.first.class.name).limit(no_of_car)
    end
  end
#  searchable :auto_index => true, :auto_remove => true  do
#      text :name, :boost => 4.0,  :as => :name_ac
#     # string :types
#    end


end 