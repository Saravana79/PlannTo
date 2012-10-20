class AttributeTag < Item
  has_many :item_attribute_tag_relations
  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 4.0,  :as => :name_ac
    string :name
    string :status
   end


end