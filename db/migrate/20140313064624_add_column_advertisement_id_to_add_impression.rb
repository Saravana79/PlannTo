class AddColumnAdvertisementIdToAddImpression < ActiveRecord::Migration
  def change
    add_column :add_impressions, :advertisement_id, :integer
  end
end
