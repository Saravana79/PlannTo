# To change this template, choose Tools | Templates
# and open the template in the editor.

class ItemtypeTag < Item
  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 6.0,  :as => :name_ac
    string :name
    string :status
    integer :orderbyid  do |item|
      item.itemtype.orderby
    end
    time :created_at
   end
end
