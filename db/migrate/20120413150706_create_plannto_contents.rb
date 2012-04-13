class CreatePlanntoContents < ActiveRecord::Migration
  def change
    create_table :plannto_contents do |t|
      t.string :field1
    end
    create_citier_view(PlanntoContent)
  end
end
