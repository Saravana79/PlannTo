class CreateBrowserPreferences < ActiveRecord::Migration
  def change
    create_table :browser_preferences do |t|      
      t.integer :user_id
      t.integer :search_display_attribute_id
      t.string :value_1
      t.string :value_2
      t.integer :itemtype_id

      t.timestamps
    end
  end
end
