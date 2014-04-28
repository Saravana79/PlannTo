class CreateAggregatedDetails < ActiveRecord::Migration
  def change
    create_table :aggregated_details do |t|
      t.string :entity_type
      t.integer :entity_id
      t.integer :impressions_count, :default => 0
      t.integer :clicks_count, :default => 0
      t.date :date
      t.timestamps
    end
  end
end
