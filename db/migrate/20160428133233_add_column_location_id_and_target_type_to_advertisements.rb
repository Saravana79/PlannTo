class AddColumnLocationIdAndTargetTypeToAdvertisements < ActiveRecord::Migration
  def change
    add_column :advertisements, :target_type, :string
    add_column :advertisements, :location_id, :integer
  end
end
