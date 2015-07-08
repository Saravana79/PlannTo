class AddColumnSortTypeToAdvertisement < ActiveRecord::Migration
  def change
    add_column :advertisements, :sort_type, :string, :default => "default"
  end
end
