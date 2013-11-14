class CreateImpressionMissings < ActiveRecord::Migration
  def change
    create_table :impression_missings do |t|
      t.integer :count, default: 0
      t.string :req_type, default: "PriceComparison"
      t.datetime :created_time, default: Time.now
      t.datetime :updated_time, default: Time.now
      t.string :hosted_site_url
      t.timestamps
    end
  end
end
