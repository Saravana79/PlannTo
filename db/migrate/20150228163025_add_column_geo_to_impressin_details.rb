class AddColumnGeoToImpressinDetails < ActiveRecord::Migration
  def change
    add_column :impression_details, :geo, :string
  end
end
