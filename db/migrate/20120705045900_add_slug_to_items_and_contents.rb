class AddSlugToItemsAndContents < ActiveRecord::Migration
  def change
    add_column :items, :slug, :string 
    add_column :contents, :slug, :string 
    add_index :items, :slug
    add_index :contents, :slug
    
    #To generate slugs for already created records
    Item.find_each(&:save)
    Content.find_each(&:save)
  end
end
