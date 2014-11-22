class CreateAdStatistics < ActiveRecord::Migration
  def change
    create_table :ad_statistics do |t|
      t.date :event_date
      t.string :event_type
      t.integer :count
    end
  end
end
