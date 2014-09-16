class AddColumnExcludedSiteToAdvertisements < ActiveRecord::Migration
  def change
    add_column :advertisements, :excluded_sites, :string
  end
end
