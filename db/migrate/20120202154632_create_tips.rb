class CreateTips < ActiveRecord::Migration
  def change
    create_table :tips do |t|
      t.string :title
      t.string :description
      t.references :item
      t.references :user
      
      t.timestamps
    end
  end
end
