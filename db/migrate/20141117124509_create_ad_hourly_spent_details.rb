class CreateAdHourlySpentDetails < ActiveRecord::Migration
  def change
    create_table :ad_hourly_spent_details do |t|
      t.integer :advertisement_id
      t.date :spent_date
      t.integer :hour
      t.integer :time_usage, :default => 0
      t.integer :price_usage, :default => 0
      t.timestamps
    end
  end
end
