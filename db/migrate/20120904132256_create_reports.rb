class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.string :report_type
      t.text :description
      t.string :reportable_type
      t.integer :reportable_id
      t.integer :reported_by
      t.string :report_from_page
      t.timestamps
    end
  end
end
