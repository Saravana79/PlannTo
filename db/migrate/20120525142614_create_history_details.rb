class CreateHistoryDetails < ActiveRecord::Migration
  def change
    create_table :history_details do |t|
      t.integer :user_id
      t.string :site_url
      t.string :ip_address
      t.string :plannto_location
      t.datetime :redirection_time

      t.timestamps
    end
  end
end
