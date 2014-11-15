class CreateAdReports < ActiveRecord::Migration
  def change
    create_table :ad_reports do |t|
      t.integer :advertisement_id
      t.string :report_type
      t.date :report_date
      t.date :from_date
      t.date :to_date
      t.string :filename
      t.string :status
      t.integer :reported_by
      t.timestamps
    end
  end
end
