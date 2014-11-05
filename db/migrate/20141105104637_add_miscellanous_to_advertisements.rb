class AddMiscellanousToAdvertisements < ActiveRecord::Migration
  def change
    add_column :advertisements, :miscellanous, :string
  end
end
