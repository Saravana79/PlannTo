class AddLettersCountAndWordsCountToItemProCons < ActiveRecord::Migration
  def change
    add_column :item_pro_cons, :letters_count, :int
    add_column :item_pro_cons, :words_count, :int
  end
end
