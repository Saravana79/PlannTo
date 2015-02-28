class AddColumnGeoToPublisherVendors < ActiveRecord::Migration
  def change
    add_column :publisher_vendors, :geo, :string, :default => "in"
  end
end
