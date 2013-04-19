# To change this template, choose Tools | Templates
# and open the template in the editor.

class ItemtypeTag < Item
  searchable :auto_index => true, :auto_remove => true  do
   text :name , :boost => 6.0,  :as => :name_ac do |item|
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
end
