class CreateProConCategories < ActiveRecord::Migration
  def change
    create_table :pro_con_categories do |t|
      t.integer :itemtype_id
      t.string :category
      t.string :list
      t.timestamps
    end
    ProConCategory.create(:itemtype_id => 6, category: "Design", list: "bulky, sturdy, slim, design, weight, bigger, larger, build")
    ProConCategory.create(:itemtype_id => 6, category: "Display", list: "screen, display")
    ProConCategory.create(:itemtype_id => 6, category:"Camera", list: "photo, pixels, camera")
  end
end
