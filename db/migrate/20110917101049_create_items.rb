class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string     :name,               :null => false, :limit => 2000
      t.text       :description,        :null => false
      t.string     :imageurl,           :limit => 2000
      t.references :itemtype
      t.integer    :group_id
      t.boolean    :editablebynonadmin, :null => false, :default => false
      t.boolean    :needapproval,       :null => false,:default => false
      t.boolean    :isgroupheader,      :null => false,:default => false
      t.timestamps
    end
  end
end