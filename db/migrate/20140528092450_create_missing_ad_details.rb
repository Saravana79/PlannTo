class CreateMissingAdDetails < ActiveRecord::Migration
  def change
    create_table :missing_ad_details do |t|
      t.string :url
      t.integer :count
      t.timestamps
    end
  end
end
