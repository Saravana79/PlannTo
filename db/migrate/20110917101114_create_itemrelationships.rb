class CreateItemrelationships < ActiveRecord::Migration
  def change
    create_table :itemrelationships do |t|
      t.integer 	:item_id,        :null => false
      t.integer		:relateditem_id, :null => false
      t.string		:relationtype,   :null => false
      t.timestamps
      t.timestamps
    end
  end
end