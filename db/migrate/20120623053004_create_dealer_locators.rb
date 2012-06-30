class CreateDealerLocators < ActiveRecord::Migration
  def change
    create_table :dealer_locators do |t|
      t.column :item_id, :integer
      t.column :url, :string
      t.timestamps
    end
  end
  def self.down
    drop_table :dealer_locators    
  end
end
