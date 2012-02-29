class CreateContents < ActiveRecord::Migration
  def change
    create_table :contents do |t|
      t.string		:title,  		:limit  => 200
      t.text		:description
      t.string		:type,			:null => false
      t.integer 	:created_by
      t.integer		:updated_by
      t.integer   :itemtype_id
      t.timestamps
    end
  end
end
