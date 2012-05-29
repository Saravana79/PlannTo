# To change this template, choose Tools | Templates
# and open the template in the editor.

class ItemtypeTag < Item
  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 6.0,  :as => :name_ac
    string :name
   end
end
