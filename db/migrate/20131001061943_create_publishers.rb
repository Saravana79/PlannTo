class CreatePublishers < ActiveRecord::Migration
  def change
    create_table :publishers do |t|
      t.string :publisher_url
      t.text :contact_details
      t.string :name

      t.timestamps
    end
  end
end
