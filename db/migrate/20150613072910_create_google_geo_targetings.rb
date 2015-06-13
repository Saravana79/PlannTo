class CreateGoogleGeoTargetings < ActiveRecord::Migration
  def change
    create_table :google_geo_targetings do |t|
      t.integer :criteria_id
      t.string :name
      t.string :canonical_name
      t.integer :parent_id
      t.string :country_code
      t.string :target_type
      t.string :status
      t.integer :location_id

      t.timestamps
    end
  end
end
