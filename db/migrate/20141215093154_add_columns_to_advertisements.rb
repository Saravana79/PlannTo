class AddColumnsToAdvertisements < ActiveRecord::Migration
  def change
    add_column :advertisements, :device, :string
    add_column :advertisements, :affiliate_id, :string
    add_column :advertisements, :track_id, :string
  end
end
