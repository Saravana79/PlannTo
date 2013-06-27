class CreateItemProCons < ActiveRecord::Migration
  def change
    create_table :item_pro_cons do |t|
      t.integer :pro_con_category_id
      t.string :proorcon
      t.integer :item_id
      t.integer :article_content_id
      t.string :text
      t.integer :index
      t.timestamps
    end
  end
end
