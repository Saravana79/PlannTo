class CreateFields < ActiveRecord::Migration
  def change
    create_table :fields do |t|
      t.integer :id
      t.integer :itemtype_id
      t.string :name
      t.string :field_type

      t.timestamps
    end
    Field.create(:itemtype_id => 1, :name => "Date of Purchase", :field_type => "date")
    Field.create(:itemtype_id => 1, :name => "Kms Driven", :field_type => "text_field")
    Field.create(:itemtype_id => 1, :name => "Max Speed Reached", :field_type => "text_field")
    Field.create(:itemtype_id => 1, :name => "Mileage", :field_type => "text_field")
    Field.create(:itemtype_id => 6, :name => "Date of Purchase", :field_type => "date")
  end
end


