class Topic < Item
  
  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 4.0,  :as => :name_ac
    string :name

   end


end